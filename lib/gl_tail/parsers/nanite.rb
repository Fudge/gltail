# Nanite (RightScale messaging) log parser.

module GlTail::Adapters
  class Nanite < ::GlTail::Adapter
    register :nanite
    SEND_PATH = /\/(.*)$/.freeze
    RECV      = /\/(.*) from mapper, target (.*), payload (.*)/.freeze

    def parse(line)
      if line =~ /SEND/
        m = line.scan(SEND_PATH).first or return
        yield('kind' => :send, 'target' => m[0], 'failsafe' => line =~ /offline.failsafe/ ? true : false)
      elsif line =~ /RECV/
        m = line.scan(RECV).first or return
        yield('kind' => :recv, 'method' => m[0], 'target' => m[1], 'payload' => m[2])
      elsif line =~ /Error \(/
        yield('kind' => :error, 'line' => line)
      end
    end
  end
end

module GlTail::Mappers
  class Nanite < ::GlTail::Mapper
    register :nanite
    OFFLINE_COLOR = Array.new(4, 0.7).freeze
    SEND_COLOR    = [1.0, 0.4, 0.2, 1.0].freeze

    def emit(record)
      case record['kind']
      when :send
        color = record['failsafe'] ? OFFLINE_COLOR : SEND_COLOR
        add_activity(block: 'mappers', name: record['target'], size: 0.01, color: color)
      when :recv
        add_activity(block: 'agents', name: record['target'],
                     message: "#{record['method']} to #{record['target']}", size: 0.005)
      when :error
        add_activity(block: 'warnings', name: record['line'])
      end
    end
  end
end

class NaniteParser < Parser
  use_adapter :nanite
  use_mapper  :nanite
end
