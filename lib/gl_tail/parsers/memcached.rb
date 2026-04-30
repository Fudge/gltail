# Custom "n & n" memcached log: <hits> & <misses>.
# Format originally by Magnus Holm <judofyr>.

module GlTail::Adapters
  class Memcached < ::GlTail::Adapter
    register :memcached
    def parse(line)
      hits, miss = line.split(' & ').map(&:to_i)
      yield('hits' => hits, 'miss' => miss)
    end
  end
end

module GlTail::Mappers
  class Memcached < ::GlTail::Mapper
    register :memcached
    HIT_COLOR  = [0.0, 1.0, 0.0, 1.0].freeze
    MISS_COLOR = [1.0, 0.0, 0.0, 1.0].freeze
    def emit(record)
      record['hits'].times { add_activity(block: 'memcached', name: 'hit',  color: HIT_COLOR)  }
      record['miss'].times { add_activity(block: 'memcached', name: 'miss', color: MISS_COLOR) }
    end
  end
end

class MemcachedParser < Parser
  use_adapter :memcached
  use_mapper  :memcached
end
