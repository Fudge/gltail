# PureFTPD Apache-format access log parser.

module GlTail::Adapters
  class Pureftpd < ::GlTail::Adapter
    register :pureftpd
    REGEX = /^([\d\S.]+) (\S+) (\S+) \[([^\]]+)\] \"(.+?)\" (\d+) ([\S]+)/.freeze
    def parse(line)
      m = REGEX.match(line) or return
      _, host, _domain, user, _date, request, status, size = m.to_a
      method, url = request.split(' ')
      url = method if url.nil?
      user = host if user == 'ftp'
      yield('host' => host, 'user' => user, 'method' => method, 'url' => url,
            'status' => status, 'size' => size.to_i)
    end
  end
end

module GlTail::Mappers
  class Pureftpd < ::GlTail::Mapper
    register :pureftpd
    def emit(record)
      url = record['url']
      size = record['size']
      if record['method'] == 'PUT'
        add_activity(block: 'urls', name: url, size: size, type: 5)
      else
        add_activity(block: 'urls', name: url, size: size)
      end
      add_activity(block: 'sites',   name: server.name, size: size)
      add_activity(block: 'users',   name: record['user'], size: size)
      add_activity(block: 'content', name: 'file')
      add_activity(block: 'status',  name: record['status'], type: 3)
    end
  end
end

class PureftpdParser < Parser
  use_adapter :pureftpd
  use_mapper  :pureftpd
end
