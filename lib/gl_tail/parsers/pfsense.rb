# pfSense PF firewall log parser.
#
# The legacy parser had two bugs that left it broken on Ruby 3.0+:
#   1. `sourechost` typo (s/sourechost/sourcehost) — would NameError on every
#      matched line, but…
#   2. `Date.day_fraction_to_time` was removed in Ruby 3.0, so execution
#      always errored before it reached the typo.
# Both are fixed below; the time-of-day filter is preserved but disabled by
# default (recent_only: false) so the test harness can produce deterministic
# goldens. Set `recent_only: true` in YAML if you want the original 5-minute
# clog-replay filter behavior.

require 'date'

module GlTail::Adapters
  class PFSense < ::GlTail::Adapter
    register :pfsense

    LINE     = /(.*)\s(.*)\spf:\s.*\srule\s(.*)\(match\)\:\s(.*)\s\w+\son\s(\w+)\:\s\((.*)\)\s(.*)\s>\s(.*)\:\s.*/.freeze
    FLAGS    = /.*\sflags\s\[(.*)\]/.freeze
    PROTO_A  = /.*\sproto\s(.*)\s\(/.freeze
    PROTO_B  = /.*\sproto:\s(.*)\s\(/.freeze
    PROTO_C  = /.*\snext-header\s(.*)\s\(/.freeze

    def initialize(recent_only: false, recent_seconds: 300)
      @recent_only    = recent_only
      @recent_seconds = recent_seconds
    end

    def parse(line)
      return if line.include?('ICMPv6') || line.include?('icmp6')
      return unless line.include?('(match)')
      m = LINE.match(line) or return

      _, ltime, host, rule, action, int, details, src, dst = m.to_a
      if @recent_only
        ts = (Time.parse(ltime) rescue nil) or return
        return if (Time.now - ts).abs > @recent_seconds
      end

      sourcehost,      sourceport      = ip_and_port(src)
      destinationhost, destinationport = ip_and_port(dst)

      ipprotocol = 'TCP'
      if details.include?('flags ')
        flags = (FLAGS.match(details) || [])[1]
      end
      if details.include?('proto ')
        ipprotocol = (PROTO_A.match(details) || ['', 'TCP'])[1]
      elsif details.include?('proto: ')
        ipprotocol = (PROTO_B.match(details) || ['', 'TCP'])[1]
      elsif details.include?('next-header ')
        ipprotocol = (PROTO_C.match(details) || ['', 'TCP'])[1]
      end

      yield(
        'host'            => host,
        'rule'            => rule.split('/').first,
        'action'          => action,
        'int'             => int,
        'flags'           => flags,
        'ipprotocol'      => ipprotocol,
        'sourcehost'      => sourcehost,
        'sourceport'      => sourceport,
        'destinationhost' => destinationhost,
        'destinationport' => destinationport,
      )
    end

    private

    # Splits an "addr.port" or IPv6 "addr.port" form into [addr, port].
    def ip_and_port(hostwithport)
      if hostwithport.count(':') > 2  # IPv6
        if hostwithport.count('.') == 1
          host, port = hostwithport.split('.')
          [host, port]
        else
          [hostwithport, 'none']
        end
      else  # IPv4
        if hostwithport.count('.') == 4
          parts = hostwithport.split('.')
          [parts[0, 4].join('.'), parts[4]]
        else
          [hostwithport, 'none']
        end
      end.then do |h, p|
        p = p.split(':').first if p.include?(':')
        p = p.split(' ').first if p.include?(' ')
        [h, p]
      end
    end
  end
end

module GlTail::Mappers
  class PFSense < ::GlTail::Mapper
    register :pfsense

    def emit(record)
      add_activity(block: 'Flags',     name: record['flags']) if record['flags']
      add_activity(block: 'action',    name: record['action'].to_s)
      add_activity(block: 'int',       name: "#{record['host']}:#{record['int']}")
      add_activity(block: 'rule',      name: record['rule'].to_s)
      add_activity(block: 'ipprotocol', name: record['ipprotocol'].to_s)
      add_activity(block: 'sourcehost', name: record['sourcehost'].to_s)
      if record['sourceport'] != 'none'
        add_activity(block: 'sourceport', name: record['sourceport'].to_s)
      end
      add_activity(block: 'destinationhost', name: record['destinationhost'].to_s, type: 5)
      if record['destinationport'] != 'none'
        add_activity(block: 'destinationport', name: record['destinationport'].to_s, type: 5)
      end
      add_activity(block: 'sourcedestination',
                   name: "#{record['sourcehost']}#{port_suffix(record['sourceport'])} > " \
                         "#{record['destinationhost']}#{port_suffix(record['destinationport'])} (#{record['ipprotocol']})")
    end

    private

    def port_suffix(port)
      port == 'none' ? '' : ":#{port}"
    end
  end
end

class PFSenseParser < Parser
  use_adapter :pfsense
  use_mapper  :pfsense
end
