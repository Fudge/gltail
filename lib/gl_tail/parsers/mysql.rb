# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from MySQL
class MysqlParser < Parser
  def parse(line)
    add_activity(block: 'sites', name: source.name)
    case line.to_s
      when /^.*Init DB\s+(.+)/ # Get the database name
        add_activity(block: 'database', name: "mysql: #{$1}")
      when /^.*Query\s+(\S+)/  # Get the query type: SELECT, INSERT, SET, UPDATE etc.
        add_activity(block: 'database queries', name: "mysql: #{$1}")
      when /^.*Connect\s+((\S+)@\S+) on/ # Get "user" and "user@hostname"
        add_activity(block: 'logins', name: "mysql: #{$2}")
        add_event(block: 'info', name: 'MySQL Login', message: "mysql: #{$1}", update_stats: true)
      when /^.*Quit\s+/
        add_event(block: 'sites', name: source.name, message: 'mysql: Quit', update_stats: false)
      else
        # Multiline query? Do nothing yet.
    end
  end
end
