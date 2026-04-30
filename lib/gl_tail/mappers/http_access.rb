require 'gl_tail/mapper'
require 'gl_tail/http_helper'

module GlTail
  module Mappers
    # Maps a normalized HTTP-access record onto gltail activities and events.
    # The record shape matches fluentd's Apache/Nginx parser output:
    #   { 'host', 'user', 'method', 'path', 'code', 'size', 'referer', 'agent' }
    # plus optional 'vhost'.
    #
    # Behavior knobs let one mapper subsume Apache, Nginx, IIS, and Caddy
    # parsers despite their historical quirks (different content-extension
    # tables, different referrer normalization, different event sets, …).
    class HttpAccess < ::GlTail::Mapper
      register :http_access

      DEFAULT_IMG_EXT   = %w[.gif .jpg .png .ico].freeze
      DEFAULT_MOVIE_EXT = %w[.avi .ogm .flv .mpg].freeze
      DEFAULT_MUSIC_EXT = %w[.mp3 .wav .fla .aac .ogg].freeze
      DEFAULT_EVENTS    = %i[logins sales signups].freeze

      def initialize(parser,
                     parse_useragent: false,
                     users_check_rate: nil,
                     strip_referer_http_prefix: false,
                     warnings_for_4xx: false,
                     skip_nil_useragent: true,
                     img_ext: DEFAULT_IMG_EXT,
                     movie_ext: DEFAULT_MOVIE_EXT,
                     music_ext: DEFAULT_MUSIC_EXT,
                     events: DEFAULT_EVENTS,
                     login_substring: 'login',
                     register_substring: '/register')
        super(parser)
        @parse_useragent           = parse_useragent
        @users_check_rate          = users_check_rate
        @strip_referer_http_prefix = strip_referer_http_prefix
        @warnings_for_4xx          = warnings_for_4xx
        @skip_nil_useragent        = skip_nil_useragent
        @img_ext                   = img_ext
        @movie_ext                 = movie_ext
        @music_ext                 = music_ext
        @events                    = Array(events)
        @login_substring           = login_substring
        @register_substring        = register_substring
      end

      def emit(record)
        host    = record['host']
        method  = record['method'] || 'GET'
        path    = record['path']   || '/'
        code    = (record['code'] || '0').to_s
        size    = (record['size'] || 0).to_i
        referer = record['referer']
        agent   = record['agent']

        url, _qs = path.split('?', 2)

        # `referrer` here mirrors the legacy variable name kept in the activity
        # `name:` field for byte-compat with the snapshot goldens.
        referrer = referer
        referrer = nil if referrer == '-' || referrer == ''
        referrer_host = nil
        if referrer
          _, referrer_host = %r{^https?://([^/]+)}.match(referrer).to_a
          # The legacy ApacheParser only stripped "http://" — not "https://" —
          # via a literal gsub. Preserved here for byte-compat with goldens.
          referrer = referrer.sub(%r{^http://}, '') if @strip_referer_http_prefix
        end

        users_opts = { block: 'users', name: host, size: size }
        users_opts[:check_rate] = @users_check_rate if @users_check_rate

        add_activity(block: 'sites', name: server.name, size: size)
        add_activity(block: 'urls',  name: url)
        add_activity(users_opts)
        if referrer && referrer_host &&
           !referrer_host.include?(server.name.to_s) &&
           !referrer_host.include?(server.host.to_s)
          add_activity(block: 'referrers', name: referrer)
        end

        ua_name = @parse_useragent ? HttpHelper.parse_useragent(agent) : agent
        if !(@skip_nil_useragent && agent.nil?)
          add_activity(block: 'user agents', name: ua_name, type: 3)
        end

        type = classify_url(url)
        add_activity(block: 'content', name: type)
        add_activity(block: 'status',  name: code, type: 3)

        if @warnings_for_4xx && code.to_i > 400
          add_activity(block: 'warnings', name: "#{code}: #{url}")
        end

        emit_events(method, url)
      end

      private

      def classify_url(url)
        return 'image'      if @img_ext.any?   { |e| url.include?(e) }
        return 'css'        if url.include?('.css')
        return 'javascript' if url.include?('.js')
        return 'flash'      if url.include?('.swf')
        return 'movie'      if @movie_ext.any? { |e| url.include?(e) }
        return 'music'      if @music_ext.any? { |e| url.include?(e) }
        'page'
      end

      def emit_events(method, url)
        return unless method == 'POST'

        if @events.include?(:logins) && url.include?(@login_substring)
          add_event(block: 'info', name: 'Logins', message: 'Login...',
                    update_stats: true, color: [1.5, 1.0, 0.5, 1.0])
        end
        if @events.include?(:registration) && url.include?(@register_substring)
          add_event(block: 'info', name: 'Registration', message: 'Register',
                    update_stats: true, color: [1.5, 0.0, 0.0, 1.0])
        end
        if @events.include?(:sales) && url.include?('/checkout')
          add_event(block: 'info', name: 'Sales', message: '$',
                    update_stats: true, color: [1.5, 0.0, 0.0, 1.0])
        end
        if @events.include?(:signups) && (url.include?('/signup') || url.include?('/users/create'))
          add_event(block: 'info', name: 'Signups', message: 'New User...',
                    update_stats: true, color: [1.0, 1.0, 1.0, 1.0])
        end
      end
    end
  end
end
