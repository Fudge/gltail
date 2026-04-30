# Cisco ASA log parser. Class name `ASAParser` registers as :asa.

module GlTail::Adapters
  class Asa < ::GlTail::Adapter
    register :asa

    BUILT  = /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: Built (\w+)bound \w+ connection \d+ for (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+) \(.*\) to (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+)/.freeze
    URL    = /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: ([a-zA-Z0-9.]+) Accessed URL ([a-zA-Z0-9.]+):(.*)[\?]?/.freeze
    DENY   = /Deny (\S+) src (\S+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9]+) dst (\S+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9]+)/.freeze

    def parse(line)
      case
      when line.include?(': Built') && (m = BUILT.match(line))
        yield(
          'kind' => :built, 'firewall' => m[1], 'type' => m[2], 'direction' => m[3],
          'srcif' => m[4], 'src' => m[5], 'srcport' => m[6],
          'dstif' => m[7], 'dst' => m[8], 'dstport' => m[9],
        )
      when line.include?('Accessed URL') && (m = URL.match(line))
        yield(
          'kind' => :url, 'firewall' => m[1], 'type' => m[2],
          'client' => m[3], 'server' => m[4], 'url' => m[5],
        )
      when line.include?('106023: Deny') && (m = DENY.match(line))
        yield(
          'kind' => :deny_106023,
          'ipprotocol'           => m[1].upcase,
          'sourceinterface'      => m[2],
          'sourcehost'           => m[3],
          'sourceport'           => m[4],
          'destinationinterface' => m[5],
          'destinationhost'      => m[6],
          'destinationport'      => m[7],
        )
      when line.downcase.match('denied|deny|discarded|no translation group')
        yield catchall(line)
      end
    end

    private

    def catchall(line)
      ipprotocol = line.upcase.scan(/(TCP|UDP|ICMP)/)[0].join

      sourceinterface = line.scan(/on interface (\S+)/)
      sourceinterface = sourceinterface.length > 0 ? sourceinterface[0].join : 'unknown'

      hosts = line.scan(/((?:\d{1,3}\.){3}\d{1,3})/)
      sourcehost      = hosts[0].to_s
      destinationhost = hosts[1].to_s

      sourceport = line.scan(/#{sourcehost}\/([a-zA-Z0-9]+)/)
      sourceport = sourceport.length > 0 ? sourceport[0].join : '0'

      destinationport = line.scan(/#{destinationhost}\/([a-zA-Z0-9]+)/)
      destinationport = destinationport.length > 0 ? destinationport[0].join : '0'

      if sourceinterface == 'unknown'
        sinterface = line.scan(/ ([a-zA-Z0-9]+)\:#{sourcehost}/)
        sourceinterface = sinterface[0].join if sinterface.length > 0
      end

      dinterface = line.scan(/ ([a-zA-Z0-9]+)\:#{destinationhost}/)
      destinationinterface = dinterface.length > 0 ? dinterface[0].join : 'unknown'

      {
        'kind' => :catchall,
        'ipprotocol'           => ipprotocol,
        'sourcehost'           => sourcehost,
        'sourceinterface'      => sourceinterface,
        'sourceport'           => sourceport,
        'destinationhost'      => destinationhost,
        'destinationinterface' => destinationinterface,
        'destinationport'      => destinationport,
      }
    end
  end
end

module GlTail::Mappers
  class Asa < ::GlTail::Mapper
    register :asa

    def emit(record)
      case record['kind']
      when :built then emit_built(record)
      when :url   then emit_url(record)
      when :deny_106023, :catchall then emit_deny(record)
      end
    end

    private

    def emit_built(record)
      add_activity(block: 'firewall', name: record['firewall'])
      if record['direction'] == 'out'
        add_activity(block: 'hosts', name: record['src'])
        add_activity(block: 'sites', name: record['dst'])
      else
        add_activity(block: 'hosts', name: record['dst'])
        add_activity(block: 'sites', name: record['src'])
      end
    end

    def emit_url(record)
      add_activity(block: 'firewall', name: record['firewall'])
      add_activity(block: 'hosts', name: record['client'])
      add_activity(block: 'sites', name: record['server'])
      add_activity(block: 'urls',  name: record['url'])
    end

    def emit_deny(record)
      add_activity(block: 'action',               name: 'Deny',                       type: 3)
      add_activity(block: 'ipprotocol',           name: record['ipprotocol'],         type: 3)
      add_activity(block: 'sourcehost',           name: record['sourcehost'],         type: 1)
      add_activity(block: 'sourceinterface',      name: record['sourceinterface'],    type: 3)
      add_activity(block: 'sourceport',           name: record['sourceport'],         type: 3)
      add_activity(block: 'destinationhost',      name: record['destinationhost'],    type: 5)
      if record['kind'] == :deny_106023
        add_activity(block: 'destinationinterface', name: record['destinationinterface'], type: 3)
      end
      add_activity(block: 'destinationport',      name: record['destinationport'],    type: 2,
                                                  message: record['destinationport'])
    end
  end
end

class ASAParser < Parser
  use_adapter :asa
  use_mapper  :asa
end
