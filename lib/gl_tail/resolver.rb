require 'resolv-replace'

class Resolver
  @cache = { }
  @thread = nil

  @queue = Queue.new

  def self.start
    @thread = Thread.new {
      while true
        ip = @queue.pop
        next if @cache.include? ip
        begin
          timeout(2.00) {
            puts "Looking for #{ip}" if $DBG > 0
            hostname = Resolv.getname(ip)
            puts "Got #{hostname}" if $DBG > 0
            @cache[ip] = hostname
          }
        rescue Timeout::Error
          puts "Timeout!" if $DBG > 0
        rescue Resolv::ResolvError
          # No result, don't bother retrying
          @cache[ip] = ip
        end

      end
    }
  end

  def self.resolv(ip)
    return @cache[ip] if @cache[ip]
    puts "Pusing #{ip} for lookup" if $DBG > 0
    @queue.push ip
    return ip
  end

end

Resolver.start
