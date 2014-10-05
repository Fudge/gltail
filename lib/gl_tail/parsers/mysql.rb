# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from MySQL
class MysqlParser < Parser
  def parse(line)
    add_activity(block: 'sites',    name: source.name)
    if line.include? 'Init DB'
      _, db = /^.*Init DB\s+(.+)/.match(line).to_a
      add_activity(block: 'database', name: "mysql: #{db}") if db
    elsif line.include? 'Query'
      _, query = /^.*Query\s+(.+)/.match(line).to_a
      add_activity(block: 'database queries', name: "mysql: #{query.to_s.split[0].upcase}") if query
    elsif line.include? 'Connect'
      _, user = /^.*Connect\s+(.+) on/.match(line).to_a
      if user
        add_activity(block: 'logins', name: "mysql: #{user.to_s.split('@')[0]}")
        add_event(block: 'info', name: 'Logins', message: "mysql: #{user}", update_stats: true)
      end
    end
  end
end
