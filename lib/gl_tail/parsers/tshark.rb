# Wireshark/tshark output parser.

module GlTail::Adapters
  class TShark < ::GlTail::Adapter
    register :tshark
    def parse(line)
      record = { 'kinds' => [] }
      if line.include?('->')
        time, srcip, _arrow, _destip, type, _rest = line.split(' ')
        record['kinds'] << :flow
        record['srcip'] = srcip
        record['type']  = type
      end
      if line.include?('DNS Standard query A')
        _, name = line.split(' A ')
        record['kinds'] << :dns_query
        record['name']  = name
      end
      yield record unless record['kinds'].empty?
    end
  end
end

module GlTail::Mappers
  class TShark < ::GlTail::Mapper
    register :tshark
    def emit(record)
      if record['kinds'].include?(:flow)
        add_activity(block: 'users', name: record['srcip'])
        add_activity(block: 'types', name: record['type'])
      end
      if record['kinds'].include?(:dns_query) && record['name']
        add_event(block: 'status', name: 'DNS Queries',
                  message: 'DNS Request: ' + record['name'],
                  update_stats: true, color: [1.5, 1.0, 0.5, 1.0])
      end
    end
  end
end

class TSharkParser < Parser
  use_adapter :tshark
  use_mapper  :tshark
end
