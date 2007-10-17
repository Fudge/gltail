# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from MySQL
class MysqlParser < Parser
  def parse( line )
    # 071013  9:43:17       7 Query       select * from users where username='test' limit 10

    if line.include? " Query   "
      _, query = /^.* Query\s+(.+)$/.match(line).to_a

      if query
        add_activity(:block => 'sites', :name => server.name)
        add_activity(:block => 'database', :name => query)
      end

    elsif line.include? " Connect  "
      #                      8 Connect     debian-sys-maint@localhost on
      _, user = /^.* Connect\s+(.+) on\s+/.match(line).to_a
      if user
        add_activity(:block => 'logins', :name => "#{user}/mysql" )
      end
    end

  end
end
