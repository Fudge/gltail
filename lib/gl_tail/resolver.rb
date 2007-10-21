require 'resolv-replace'

class Resolver
  include GlTail::Configurable

  config_attribute :reverse_ip_lookups, "Lookup Hostnames"
  config_attribute :reverse_timeout,    "Wait how long for DNS reply [s]"

  def self.instance
    @@instance ||= Resolver.new
  end

  def initialize
    @cache = { }
    @thread = nil
    @reverse_ip_lookups = true
    @reverse_timeout = 1.5
    @queue = Queue.new
  end

  attr_reader :queue, :cache

  def start
    @thread = Thread.new {
      while @reverse_ip_lookups
        ip, element = @queue.pop
        if @cache.include? ip
          element.name = @cache[ip]
        else
          begin
            timeout(@reverse_timeout.to_f) {
              puts "[Resolver] Looking for #{ip}" if $DBG > 0
              hostname = Resolv.getname(ip)
              puts "[Resolver] Got #{hostname}[#{ip}]" if $DBG > 0
              @cache[ip] = hostname
              element.name = hostname
            }
          rescue Timeout::Error
            puts "[Resolver] Timeout!" if $DBG > 0
          rescue Resolv::ResolvError
            # No result, don't bother retrying
            @cache[ip] = ip
          end
        end
      end
    }
  end

  def lookup(ip, element)
    return ip if not @reverse_ip_lookups

    if name = cache[ip]
      return name
    else
      puts "[Resolver] Pushing #{ip} for lookup" if $DBG > 0
      queue.push([ip, element])
    end

    return ip

  end

  def self.resolv(ip, element)
    instance.lookup(ip, element)
  end

end

Resolver.instance.start
