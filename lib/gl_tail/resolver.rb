require 'resolv-replace'

class Resolver
  include GlTail::Configurable

  config_attribute :reverse_ip_lookups, "Lookup Hostnames"

  def self.instance
    @@instance ||= Resolver.new
  end

  def initialize
    @cache = { }
    @thread = nil
    @reverse_ip_lookups = true
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
            timeout(2.00) {
              puts "Looking for #{ip}" if $DBG > 0
              hostname = Resolv.getname(ip)
              puts "Got #{hostname}[#{ip}]" if $DBG > 0
              @cache[ip] = hostname
              element.name = hostname
            }
          rescue Timeout::Error
            puts "Timeout!" if $DBG > 0
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
      puts "Pusing #{ip} for lookup" if $DBG > 0
      queue.push([ip, element])
    end

    return ip

  end

  def self.resolv(ip, element)
    instance.lookup(ip, element)
  end

end

Resolver.instance.start
