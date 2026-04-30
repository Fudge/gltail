# PostgreSQL log parser.

module GlTail::Adapters
  class PostgreSQL < ::GlTail::Adapter
    register :postgresql
    PREFIXED = /^\[(.*), (.* .* .*)\] LOG:  ([a-zA-Z0-9\s]*): (.*)/.freeze
    SYSLOG   = /postgres\[\d+\]: \[\d+-\d+\] \[(.*), (.* .* .*)\] LOG:  ([a-zA-Z0-9\s]*): (.*)/.freeze
    NAKED    = /(.* .* .*) LOG:  ([a-zA-Z0-9\s]*): (.*)/.freeze

    def parse(line)
      record = {}
      if (m = PREFIXED.match(line))
        record['database'] = m[1]
        record['activity'] = m[3]
        record['description'] = m[4]
      elsif (m = SYSLOG.match(line))
        record['database'] = m[1]
        record['activity'] = m[3]
        record['description'] = m[4]
      elsif (m = NAKED.match(line))
        record['activity'] = m[2]
        record['description'] = m[3]
      else
        return
      end

      record['activity'] = 'vacuum' if record['description'].include?('vacuum') || record['activity'] == 'autovacuum'
      yield record
    end
  end
end

module GlTail::Mappers
  class PostgreSQL < ::GlTail::Mapper
    register :postgresql
    def emit(record)
      if record['database']
        add_activity(block: 'database', name: record['database'], size: 0.2)
      end

      activity    = record['activity']
      description = record['description']
      case activity
      when 'duration'
        add_activity(block: 'database', name: 'duration', size: description.to_f / 100.0)
      when 'statement'
        add_activity(block: 'database', name: 'activity', size: 0.2)
      when 'connection authorized', 'disconnection'
        add_activity(block: 'database', name: 'login/logout', size: 0.2)
      when 'vacuum'
        add_event(block: 'database', name: 'vacuum', message: description,
                  update_stats: true, color: [1.0, 1.0, 0.0, 1.0])
      end
    end
  end
end

class PostgreSQLParser < Parser
  use_adapter :postgresql
  use_mapper  :postgresql
end
