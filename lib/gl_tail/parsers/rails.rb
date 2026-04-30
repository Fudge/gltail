# Rails 2.x access log parser.

module GlTail::Adapters
  class Rails < ::GlTail::Adapter
    register :rails
    OLD_COMPLETE = /^Completed in ([\d.]+) .* \[([^\]]+)\]/.freeze
    NEW_COMPLETE = /^Completed in ([\d]+)ms .* \[([^\]]+)\]/.freeze
    PROCESSING   = /^Processing .* \(for (\d+.\d+.\d+.\d+) at .*\).*$/.freeze
    ERROR        = /^([^ ]+Error) \((.*)\):/.freeze

    def parse(line)
      if (m = NEW_COMPLETE.match(line))
        url = m[2]
        url = nil if url == 'http:// /'
        ms  = m[1].to_f / 1000
        yield('kind' => :complete, 'ms' => ms, 'url' => url) if url
      elsif (m = OLD_COMPLETE.match(line))
        url = m[2]
        url = nil if url == 'http:// /'
        yield('kind' => :complete, 'ms' => m[1].to_f, 'url' => url) if url
      elsif line.include?('Processing ') && (m = PROCESSING.match(line))
        yield('kind' => :processing, 'host' => m[1])
      elsif line.include?('Error (') && (m = ERROR.match(line))
        yield('kind' => :error, 'error' => m[1], 'msg' => m[2])
      end
    end
  end
end

module GlTail::Mappers
  class Rails < ::GlTail::Mapper
    register :rails

    def emit(record)
      case record['kind']
      when :complete
        emit_complete(record)
      when :processing
        add_activity(block: 'users', name: record['host'])
      when :error
        add_event(block: 'info', name: 'Exceptions', message: record['error'],
                  update_stats: true, color: [1.0, 0.0, 0.0, 1.0])
        add_event(block: 'info', name: 'Exceptions', message: record['msg'],
                  update_stats: false, color: [1.0, 0.0, 0.0, 1.0])
        add_activity(block: 'warnings', name: record['msg'])
      end
    end

    private

    def emit_complete(record)
      _, host, url = %r{^https?://([^/]*)(.*)}.match(record['url']).to_a
      ms = record['ms']
      add_activity(block: 'sites', name: host, size: ms)
      add_activity(block: 'urls', name: HttpHelper.generalize_url(url), size: ms)
      add_activity(block: 'slow requests', name: HttpHelper.generalize_url(url), size: ms)
      add_activity(block: 'content', name: 'page')
      add_event(block: 'info', name: 'Logins',  message: 'Login...', update_stats: true,
                color: [0.5, 1.0, 0.5, 1.0]) if url.include?('/login')
      add_event(block: 'info', name: 'Sales',   message: '$',        update_stats: true,
                color: [1.5, 0.0, 0.0, 1.0]) if url.include?('/checkout')
      add_event(block: 'info', name: 'Signups', message: 'New User...', update_stats: true,
                color: [1.0, 1.0, 1.0, 1.0]) if url.include?('/signup') || url.include?('/users/create')
    end
  end
end

class RailsParser < Parser
  use_adapter :rails
  use_mapper  :rails
end
