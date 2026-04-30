# BIND/named query log parser.

module GlTail::Adapters
  class Named < ::GlTail::Adapter
    register :named
    REGEX = /(\d+-\w+-\d+) (\d+:\d+:\d+\.\d+) client (?<host>\d+\.\d+\.\d+\.\d+)#(\d+) \((.+)\): query: (?<query>.+) (?<type>\S+) (?<type2>\S+) \((.*)\)/.freeze
    def parse(line)
      m = REGEX.match(line) or return
      yield(
        'host'  => m[:host],
        'query' => m[:query],
        'type'  => m[:type],
        'type2' => m[:type2],
      )
    end
  end
end

module GlTail::Mappers
  class Named < ::GlTail::Mapper
    register :named
    TYPE_SIZE = { A: 30, SRV: 40, MX: 50, SOA: 60, TXT: 70, AAAA: 80, PTR: 90, ANY: 100 }.freeze

    def emit(record)
      add_activity(block: 'sites',     name: server.name)
      add_activity(block: 'types',     name: "#{record['type']} #{record['type2']}")
      add_activity(block: 'hosts',     name: record['host'], size: 1)
      add_activity(block: 'dns query', name: record['query'], size: TYPE_SIZE[record['type'].to_sym] || 150)
    end
  end
end

class NamedParser < Parser
  use_adapter :named
  use_mapper  :named
end
