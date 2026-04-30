module GlTail
  # An Adapter turns a raw log line into zero or more normalized record hashes.
  # Subclasses implement #parse(line) { |record| ... } in the same shape the
  # fluentd plugin parsers use, so that fluentd's own parsers and our regex /
  # JSON shims share one interface.
  #
  # The record contract is open — each Mapper documents the keys it expects.
  # For HTTP-access logs the canonical keys are: host, user, method, path,
  # code, size, referer, agent.
  class Adapter
    # Build an Adapter from a symbolic name. Subclasses register themselves
    # via Adapter.register(:name).
    def self.register(name)
      @@registry ||= {}
      @@registry[name.to_sym] = self
    end

    def self.build(spec)
      case spec
      when Adapter
        spec
      when Symbol, String
        klass = (@@registry || {})[spec.to_sym] or
          raise "no adapter registered as :#{spec} — known: #{(@@registry || {}).keys.sort.inspect}"
        klass.new
      when Array
        name, *args = spec
        klass = (@@registry || {})[name.to_sym] or
          raise "no adapter registered as :#{name}"
        klass.new(*args)
      else
        raise "cannot build adapter from #{spec.inspect}"
      end
    end

    # Yields a Hash record for each parseable line. Lines that do not parse
    # should be silently skipped (yield nothing) — the parsers Caddy emits
    # routinely include non-access JSON we don't care about.
    def parse(line)
      raise NotImplementedError, "#{self.class} must implement #parse(line) { |record| ... }"
    end
  end
end
