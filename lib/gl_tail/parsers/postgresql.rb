# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles PostgreSQL logs
class PostgreSQLParser < Parser
  def parse( line )
    # here's an example parser for postgres log files; adjust accordingly for different logfile setups.
    #
    # postgresql.conf:
    #    log_line_prefix = '[%d, %t] '
    #    log_connections = on
    #    log_disconnections = on
    #    log_duration = on
    #    log_statement = 'all'

    _, database, datetime, activity, description = /^\[(.*), (.* .* .*)\] LOG:  ([a-zA-Z0-9\s]*): (.*)/.match(line).to_a

    unless _
      _, database, datetime, activity, description = /postgres\[\d+\]: \[\d+-\d+\] \[(.*), (.* .* .*)\] LOG:  ([a-zA-Z0-9\s]*): (.*)/.match(line).to_a
      syslog = true if _
    end

    if database
      add_activity(:block => 'database', :name => database, :size => 0.2)
    else
      _, datetime, activity, description = /(.* .* .*) LOG:  ([a-zA-Z0-9\s]*): (.*)/.match(line).to_a
    end

    if activity
      activity = 'vacuum' if(description.include?('vacuum') || activity == 'autovacuum')
      case activity
      when 'duration'
        add_activity(:block => 'database', :name => 'duration', :size => description.to_f / 100.0)
      when 'statement'
        add_activity(:block => 'database', :name => 'activity', :size => 0.2)
      when 'connection authorized', 'disconnection'
        add_activity(:block => 'database', :name => 'login/logout', :size => 0.2)
      when 'vacuum'
        add_event(:block => 'database', :name => 'vacuum', :message => description, :update_stats => true, :color => [1.0, 1.0, 0.0, 1.0])
      end
    end

  end
end
