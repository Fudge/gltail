# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles squid logs
class SquidParser < Parser
  def parse( line )
    _, delay, host, size, method, uri, user = /\d+.\d+ +(\d+) +(\d+.\d+.\d+.\d+.\d+).+ (\d+) (.+) (.+) (.+) .+ .+/.match(line).to_a
    if host
      if method != 'ICP_QUERY'
        size = size.to_f / 100000.0
        #Uncomment if you authenticate to use the proxy
        #add_activity(:block => 'users', :name => user, :size => size)
        add_activity(:block => 'hosts', :name => host, :size => size)
        add_activity(:block => 'types', :name => method, :size => size) if method
        _, site = /http:\/\/(.+?)\/.+/.match(uri).to_a
        if site:
            add_activity(:block => 'sites', :name => site, :size => size)
        end
      end
    end
  end
end
