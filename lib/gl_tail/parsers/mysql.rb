# MySQL general query log parser.

module GlTail::Adapters
  class Mysql < ::GlTail::Adapter
    register :mysql
    def parse(line)
      kind, *args =
        case line.to_s
        when /^.*Init DB\s+(.+)/
          [:init_db, $1]
        when /^.*Query\s+(\S+)/
          [:query, $1]
        when /^.*Connect\s+((\S+)@\S+) on/
          [:connect, $1, $2]
        when /^.*Quit\s+/
          [:quit]
        end
      # Always yield — the legacy parser adds the `sites` activity for every
      # line regardless of whether a branch matched.
      yield('kind' => kind, 'args' => args)
    end
  end
end

module GlTail::Mappers
  class Mysql < ::GlTail::Mapper
    register :mysql
    def emit(record)
      add_activity(block: 'sites', name: server.name)
      case record['kind']
      when :init_db
        add_activity(block: 'database', name: "mysql: #{record['args'][0]}")
      when :query
        add_activity(block: 'database queries', name: "mysql: #{record['args'][0]}")
      when :connect
        full, user = record['args']
        add_activity(block: 'logins', name: "mysql: #{user}")
        add_event(block: 'info', name: 'MySQL Login', message: "mysql: #{full}", update_stats: true)
      when :quit
        add_event(block: 'sites', name: server.name, message: 'mysql: Quit', update_stats: false)
      end
    end
  end
end

class MysqlParser < Parser
  use_adapter :mysql
  use_mapper  :mysql
end
