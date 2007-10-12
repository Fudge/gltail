# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles qmail logs
class QmailParser < Parser
  def parse( line )
    if line.include?(' logged in from ')
      _, user, host, ip = /: User \'([^']+)\' of \'([^']+)\' logged in from (\d+.\d+.\d+.\d+)/.match(line).to_a
      if host
        add_activity(:block => 'logins', :name => user+'@'+host, :size => 0.05)
        add_activity(:block => 'sites', :name => server.name, :size => 0.05)
      end
    elsif line.include?(' to local ')
      _, prefix, host = / to local ([^@]+)@(.*)/.match(line).to_a
      if host
        add_activity(:block => 'mail to', :name => host, :size => 0.05)
        add_activity(:block => 'sites', :name => server.name, :size => 0.05)
      end
    elsif line.include?(' to remote ')
      _, prefix, host = / to remote ([^@]+)@(.*)/.match(line).to_a
      if host
        add_activity(:block => 'mail from', :name => host, :size => 0.05)
        add_activity(:block => 'sites', :name => server.name, :size => 0.05)
      end
    end
  end
end
