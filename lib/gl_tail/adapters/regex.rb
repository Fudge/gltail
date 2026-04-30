require 'gl_tail/adapter'

module GlTail
  module Adapters
    # Generic regex adapter for the legacy parsers (postfix, mysql, named, …)
    # that don't fit any stock fluentd parser. Subclasses or instances declare
    # a regex and the names of its captures, and #parse yields a Hash record.
    #
    # Lines that don't match are silently skipped (yield nothing).
    class Regex < ::GlTail::Adapter
      register :regex

      def initialize(regex, fields)
        @regex = regex
        @fields = fields.map(&:to_s)
      end

      def parse(line)
        m = @regex.match(line) or return
        record = {}
        @fields.each_with_index do |name, i|
          record[name] = m[i + 1]
        end
        yield record
      end
    end
  end
end
