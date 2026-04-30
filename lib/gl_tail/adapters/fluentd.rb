require 'gl_tail/adapter'

# Lazy-load fluentd: it pulls in ~30 gems (msgpack, async, serverengine, …)
# and we only need it when an Adapters::Fluentd is actually instantiated.
module GlTail
  module Adapters
    class Fluentd < ::GlTail::Adapter
      register :fluentd

      # Wrap one of fluentd's built-in parser plugins.
      # @param parser [Symbol] one of :apache2, :apache_error, :nginx, :json,
      #   :csv, :tsv, :ltsv, :syslog, etc. — must match a Fluent::Plugin::*Parser.
      # @param config [Hash] forwarded as fluentd plugin config (e.g. `format: '...'`).
      def initialize(parser, config = {})
        @plugin_name = parser.to_sym
        @config_hash = config
      end

      def parse(line)
        plugin.parse(line) { |_time, record| yield record }
      end

      private

      def plugin
        @plugin ||= build_plugin
      end

      def build_plugin
        require 'fluent/engine'
        require 'fluent/config/element'
        require "fluent/plugin/parser_#{@plugin_name}"
        klass = Fluent::Plugin.const_get("#{camelize(@plugin_name)}Parser")
        instance = klass.new
        instance.configure(Fluent::Config::Element.new('ROOT', '', stringify(@config_hash), []))
        instance
      end

      # Verified for: :apache2, :apache_error, :nginx, :json, :regexp, :syslog,
      # :none, :multiline. Acronymic names like :csv/:tsv/:ltsv would resolve
      # to Csv/Tsv/Ltsv here and miss CSVParser/TSVParser/LabeledTSVParser —
      # add a class lookup table if you need those.
      def camelize(sym)
        sym.to_s.split('_').map { |s| s == 'json' ? 'JSON' : s.capitalize }.join
      end

      def stringify(h)
        h.transform_keys(&:to_s).transform_values(&:to_s)
      end
    end
  end
end
