# Cisco PIX / FWSM firewall log parser. Class registers as :pix.

module GlTail::Adapters
  class Pix < ::GlTail::Adapter
    register :pix
    BUILT  = /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: Built (\w+)bound \w+ connection \d+ for (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+) \(.*\) to (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+)/.freeze
    URL    = /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: ([a-zA-Z0-9.]+) Accessed URL ([a-zA-Z0-9.]+):(.*)[\?]?/.freeze

    def parse(line)
      if line.include?(': Built') && (m = BUILT.match(line))
        yield(
          'kind' => :built, 'firewall' => m[1], 'type' => m[2], 'direction' => m[3],
          'srcif' => m[4], 'src' => m[5], 'srcport' => m[6],
          'dstif' => m[7], 'dst' => m[8], 'dstport' => m[9],
        )
      elsif line.include?('Accessed URL') && (m = URL.match(line))
        yield(
          'kind' => :url, 'firewall' => m[1], 'type' => m[2],
          'client' => m[3], 'server' => m[4], 'url' => m[5],
        )
      end
    end
  end
end

module GlTail::Mappers
  class Pix < ::GlTail::Mapper
    register :pix
    def emit(record)
      add_activity(block: 'firewall', name: record['firewall'])
      case record['kind']
      when :built
        if record['direction'] == 'out'
          add_activity(block: 'hosts', name: record['src'])
          add_activity(block: 'sites', name: record['dst'])
        else
          add_activity(block: 'hosts', name: record['dst'])
          add_activity(block: 'sites', name: record['src'])
        end
      when :url
        add_activity(block: 'hosts', name: record['client'])
        add_activity(block: 'sites', name: record['server'])
        add_activity(block: 'urls',  name: record['url'])
      end
    end
  end
end

class PixParser < Parser
  use_adapter :pix
  use_mapper  :pix
end
