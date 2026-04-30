# Rails-via-syslog access log parser.

module GlTail::Adapters
  class RailsSyslog < ::GlTail::Adapter
    register :railssyslog
    COMPLETED  = /^.*\[[\d.]+\]: Completed in ([\d.]+)ms .* \[([^\]]+)\]/.freeze
    PROCESSING = /^.*: Processing .* \(for (\d+.\d+.\d+.\d+) at .*\).*$/.freeze
    ERROR      = /^([^ ]+Error) \((.*)\):/.freeze
    SQL_LOAD   = /^.*\[[\d.]+\]: ([A-Za-z]+) Load \(([\d.]+)ms\)[\s]+SELECT.*$/.freeze
    SQL_UPDATE = /^.*\[[\d.]+\]: ([A-Za-z]+) Update \(([\d.]+)ms\)[\s]+UPDATE.*$/.freeze
    SQL_INSERT = /^.*\[[\d.]+\]: SQL \(([\d.]+)ms\)[\s]+INSERT INTO \"([A-Za-z_]+)\".*$/.freeze

    def parse(line)
      if (m = COMPLETED.match(line))
        yield('kind' => :completed, 'ms' => m[1].to_f, 'url' => m[2])
      elsif line.include?('Processing ') && (m = PROCESSING.match(line))
        yield('kind' => :processing, 'host' => m[1])
      elsif line.include?('Error (') && (m = ERROR.match(line))
        yield('kind' => :error, 'error' => m[1], 'msg' => m[2])
      elsif line.include?('SELECT ') && (m = SQL_LOAD.match(line))
        yield('kind' => :select, 'model' => m[1], 'ms' => m[2].to_f)
      elsif line.include?('UPDATE ') && (m = SQL_UPDATE.match(line))
        yield('kind' => :update, 'model' => m[1], 'ms' => m[2].to_f)
      elsif line.include?('INSERT INTO ') && (m = SQL_INSERT.match(line))
        yield('kind' => :insert, 'table' => m[2], 'ms' => m[1].to_f)
      end
    end
  end
end

module GlTail::Mappers
  class RailsSyslog < ::GlTail::Mapper
    register :railssyslog
    def emit(record)
      case record['kind']
      when :completed
        _, host, url = %r{^https?://([^/]*)(.*)}.match(record['url']).to_a
        ms = record['ms']
        add_activity(block: 'sites', name: host, size: ms)
        add_activity(block: 'urls', name: HttpHelper.generalize_url(url), size: ms)
        add_activity(block: 'slow requests', name: HttpHelper.generalize_url(url), size: ms)
        add_activity(block: 'content', name: 'page')
        add_event(block: 'info', name: 'Logins',  message: 'Login...', update_stats: true,
                  color: [0.5, 1.0, 0.5, 1.0]) if url.include?('/login')
        add_event(block: 'info', name: 'Sales',   message: '$',        update_stats: true,
                  color: [1.5, 0.0, 0.0, 1.0]) if url.include?('/checkout')
        add_event(block: 'info', name: 'Signups', message: 'New User...', update_stats: true,
                  color: [1.0, 1.0, 1.0, 1.0]) if url.include?('/signup') || url.include?('/users/create')
      when :processing
        add_activity(block: 'users', name: record['host'])
      when :error
        add_event(block: 'info', name: 'Exceptions', message: record['error'],
                  update_stats: true,  color: [1.0, 0.0, 0.0, 1.0])
        add_event(block: 'info', name: 'Exceptions', message: record['msg'],
                  update_stats: false, color: [1.0, 0.0, 0.0, 1.0])
        add_activity(block: 'warnings', name: record['msg'])
      when :select
        add_activity(block: 'sqlselect', name: record['model'], size: record['ms'])
      when :update
        add_activity(block: 'sqlupdate', name: record['model'], size: record['ms'])
      when :insert
        add_activity(block: 'sqlinsert', name: record['table'], size: record['ms'])
      end
    end
  end
end

class RailsSyslogParser < Parser
  use_adapter :railssyslog
  use_mapper  :railssyslog
end
