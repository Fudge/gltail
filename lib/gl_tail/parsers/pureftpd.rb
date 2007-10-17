# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from PureFTPD
class PureftpdParser < Parser
  def parse( line )
    _, host, domain, user, date, url, status, size = /^([\d\S.]+) (\S+) (\S+) \[([^\]]+)\] \"(.+?)\" (\d+) ([\S]+)/.match(line).to_a

    if host
      user = host if user == 'ftp'

      method, url = url.split(" ")
      url = method if url.nil?

      if method == "PUT"
        add_activity(:block => 'urls', :name => url, :size => size.to_i, :type => 5)
      else
        add_activity(:block => 'urls', :name => url, :size => size.to_i)
      end
      add_activity(:block => 'sites', :name => server.name, :size => size.to_i) # Size of activity based on size of request
      add_activity(:block => 'users', :name => user, :size => size.to_i)

      add_activity(:block => 'content', :name => 'file')
      add_activity(:block => 'status', :name => status, :type => 3) # don't show a blob
    end
  end
end
