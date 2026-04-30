module GlTail
  # A Mapper turns normalized records (from an Adapter) into the gltail
  # domain-level events: add_activity / add_event calls on the source.
  # Mappers are stateless aside from the Parser they're bound to (which they
  # use to reach the Source for name/host metadata and to dispatch events).
  class Mapper
    def self.register(name)
      @@registry ||= {}
      @@registry[name.to_sym] = self
    end

    def self.build(spec, parser)
      case spec
      when Mapper
        spec
      when Symbol, String
        klass = lookup(spec)
        klass.new(parser)
      when Array
        name, opts = spec
        klass = lookup(name)
        opts ? klass.new(parser, **opts) : klass.new(parser)
      else
        raise "cannot build mapper from #{spec.inspect}"
      end
    end

    def self.lookup(name)
      (@@registry || {})[name.to_sym] or
        raise "no mapper registered as :#{name} — known: #{(@@registry || {}).keys.sort.inspect}"
    end

    def initialize(parser)
      @parser = parser
    end

    def server
      @parser.source
    end

    def add_activity(opts)
      @parser.add_activity(opts)
    end

    def add_event(opts)
      @parser.add_event(opts)
    end

    def emit(record)
      raise NotImplementedError, "#{self.class} must implement #emit(record)"
    end
  end
end
