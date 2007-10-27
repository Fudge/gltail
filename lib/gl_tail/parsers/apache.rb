# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles access_logs in combined format from Apache
class ApacheParser < Parser
  def parse( line )
    _, host, user, domain, date, url, status, size, referrer, useragent = /([\d\S.]+) (\S+) (\S+) \[([^\]]+)\] \"(.+?)\" (\d+) ([\S]+) \"([^\"]+)\" \"([^\"]+)\"/.match(line).to_a

    unless host
      _, host, user, domain, date, url, status, size = /([\d\S.]+) (\S+) (\S+) \[([^\]]+)\] \"(.+?)\" (\d+) ([\S]+)/.match(line).to_a
    end

    if host
      _, referrer_host, referrer_url = /^http[s]?:\/\/([^\/]+)(\/.*)/.match(referrer).to_a if referrer
      method, url, http_version = url.split(" ")
      url = method if url.nil?
      url, parameters = url.split('?')

      referrer.gsub!(/http:\/\//,'') if referrer

      add_activity(:block => 'sites', :name => server.name, :size => size.to_i) # Size of activity based on size of request
      add_activity(:block => 'urls', :name => url)
      add_activity(:block => 'users', :name => host, :size => size.to_i)
      add_activity(:block => 'referrers', :name => referrer) unless (referrer.nil? || referrer_host.nil? || referrer_host.include?(server.name) || referrer_host.include?(server.host))
      add_activity(:block => 'user agents', :name => HttpHelper.parse_useragent(useragent), :type => 3) unless useragent.nil?

      if( url.include?('.gif') || url.include?('.jpg') || url.include?('.png') || url.include?('.ico'))
        type = 'image'
      elsif url.include?('.css')
        type = 'css'
      elsif url.include?('.js')
        type = 'javascript'
      elsif url.include?('.swf')
        type = 'flash'
      elsif( url.include?('.avi') || url.include?('.ogm') || url.include?('.flv') || url.include?('.mpg') )
        type = 'movie'
      elsif( url.include?('.mp3') || url.include?('.wav') || url.include?('.fla') || url.include?('.aac') || url.include?('.ogg'))
        type = 'music'
      else
        type = 'page'
      end
      add_activity(:block => 'content', :name => type)
      add_activity(:block => 'status', :name => status, :type => 3) # don't show a blob

      add_activity(:block => 'warnings', :name => "#{status}: #{url}") if status.to_i > 400

      # Events to pop up
      add_event(:block => 'info', :name => "Logins", :message => "Login...", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('login')
      add_event(:block => 'info', :name => "Sales", :message => "$", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if method == "POST" && url.include?('/checkout')
      add_event(:block => 'info', :name => "Signups", :message => "New User...", :update_stats => true, :color => [1.0, 1.0, 1.0, 1.0]) if( method == "POST" && (url.include?('/signup') || url.include?('/users/create')))
    end
  end
end
