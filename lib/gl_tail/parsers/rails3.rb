# Rails 3 access log parser.

module GlTail::Adapters
  class Rails3 < ::GlTail::Adapter
    register :rails3
    STARTED   = /^Started (GET|POST|PUT|DELETE) "(.*)" for (\d+\.\d+\.\d+\.\d+) at .*$/.freeze
    COMPLETED = /^Completed (\d\d\d) .* in (\d+)ms/.freeze
    ERROR     = /^([^ ]+Error) \((.*)\):/.freeze

    def parse(line)
      if (m = STARTED.match(line))
        yield('kind' => :started, 'method' => m[1], 'url' => m[2], 'host' => m[3])
      elsif (m = COMPLETED.match(line))
        yield('kind' => :completed, 'status' => m[1], 'ms' => m[2].to_f / 1000)
      elsif (m = ERROR.match(line))
        yield('kind' => :error, 'error' => m[1], 'msg' => m[2])
      end
    end
  end
end

module GlTail::Mappers
  class Rails3 < ::GlTail::Mapper
    register :rails3
    def emit(record)
      case record['kind']
      when :started
        add_activity(block: 'urls',    name: HttpHelper.generalize_url(record['url']))
        add_activity(block: 'users',   name: record['host'])
        add_activity(block: 'content', name: 'page')
      when :completed
        size = record['ms']
        add_activity(block: 'status', name: record['status'], size: size)
        add_activity(block: 'sites',  name: server.name,      size: size)
      when :error
        add_event(block: 'info', name: 'Exceptions', message: record['error'],
                  update_stats: true,  color: [1.0, 0.0, 0.0, 1.0])
        add_event(block: 'info', name: 'Exceptions', message: record['msg'],
                  update_stats: false, color: [1.0, 0.0, 0.0, 1.0])
        add_activity(block: 'warnings', name: record['msg'])
      end
    end
  end
end

class Rails3Parser < Parser
  use_adapter :rails3
  use_mapper  :rails3
end
