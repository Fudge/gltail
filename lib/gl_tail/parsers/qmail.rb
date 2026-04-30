# qmail log parser.

module GlTail::Adapters
  class Qmail < ::GlTail::Adapter
    register :qmail
    LOGIN     = /: User '([^']+)' of '([^']+)' logged in from (\d+.\d+.\d+.\d+)/.freeze
    LOCAL     = / to local ([^@]+)@(.*)/.freeze
    REMOTE    = / to remote ([^@]+)@(.*)/.freeze

    def parse(line)
      if line.include?(' logged in from ') && (m = LOGIN.match(line))
        yield('kind' => :login, 'user' => m[1], 'host' => m[2], 'ip' => m[3])
      elsif line.include?(' to local ') && (m = LOCAL.match(line))
        yield('kind' => :local, 'host' => m[2])
      elsif line.include?(' to remote ') && (m = REMOTE.match(line))
        yield('kind' => :remote, 'host' => m[2])
      end
    end
  end
end

module GlTail::Mappers
  class Qmail < ::GlTail::Mapper
    register :qmail
    def emit(record)
      case record['kind']
      when :login
        add_activity(block: 'logins', name: "#{record['user']}@#{record['host']}", size: 0.05)
        add_activity(block: 'sites',  name: server.name, size: 0.05)
      when :local
        add_activity(block: 'mail to',   name: record['host'], size: 0.05)
        add_activity(block: 'sites',     name: server.name, size: 0.05)
      when :remote
        add_activity(block: 'mail from', name: record['host'], size: 0.05)
        add_activity(block: 'sites',     name: server.name, size: 0.05)
      end
    end
  end
end

class QmailParser < Parser
  use_adapter :qmail
  use_mapper  :qmail
end
