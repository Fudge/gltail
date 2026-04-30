# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

require 'gl_tail/http_helper'
require 'gl_tail/adapter'
require 'gl_tail/mapper'

class Parser
  attr_reader :source

  def initialize( source )
    @source = source
  end

  # DEPRECATED?
  def server
    @source
  end

  def self::inherited( klass )
    parser_name = klass.to_s.sub( /Parser$/, '' ).downcase.intern

    @registry ||= {}
    @registry[ parser_name ] = klass
  end

  def self::registry
    return @registry
  end

  # New-style parsers declare an adapter (line → record) and a mapper
  # (record → activities/events). Legacy parsers that override #parse never
  # call these and keep working unchanged.
  def self.use_adapter(spec)
    @adapter_spec = spec
  end

  def self.use_mapper(spec)
    @mapper_spec = spec
  end

  def self.adapter_spec; @adapter_spec; end
  def self.mapper_spec;  @mapper_spec;  end

  def adapter
    @adapter ||= GlTail::Adapter.build(self.class.adapter_spec) if self.class.adapter_spec
  end

  def mapper
    @mapper ||= GlTail::Mapper.build(self.class.mapper_spec, self) if self.class.mapper_spec
  end

  def parse( line )
    if adapter && mapper
      adapter.parse(line) { |record| mapper.emit(record) }
    else
      raise NotImplementedError, 'Concrete parsers must implement #parse() or declare use_adapter / use_mapper'
    end
  end

  # dsl-ish helper methods so the parsers don't call server.add_* anymore.  That
  # seems magical now that server isn't be explicitly passed anymore.
  def add_activity( opts = {} )
    @source.add_activity( opts )
  end

  def add_event( opts = {} )
    @source.add_event( opts )
  end
end
