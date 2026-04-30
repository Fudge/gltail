# Squid native log format parser.

module GlTail::Adapters
  class Squid < ::GlTail::Adapter
    register :squid
    REGEX = /\d+.\d+ +(\d+) +(\d+.\d+.\d+.\d+.\d+).+ (\d+) (.+) (.+) (.+) .+ .+/.freeze
    def parse(line)
      m = REGEX.match(line) or return
      _, delay, host, size, method, uri, user = m.to_a
      yield(
        'delay'  => delay,
        'host'   => host,
        'size'   => size,
        'method' => method,
        'uri'    => uri,
        'user'   => user,
      )
    end
  end
end

module GlTail::Mappers
  class Squid < ::GlTail::Mapper
    register :squid
    def emit(record)
      method = record['method']
      return if method == 'ICP_QUERY'

      size = record['size'].to_f / 100000.0
      add_activity(block: 'hosts', name: record['host'], size: size)
      add_activity(block: 'types', name: method, size: size) if method

      _, site = %r{http://(.+?)/.+}.match(record['uri']).to_a
      add_activity(block: 'sites', name: site, size: size) if site
    end
  end
end

class SquidParser < Parser
  use_adapter :squid
  use_mapper  :squid
end
