# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

require 'lib/http_helper'

class Parser
  attr_reader :server

  def initialize( server )
    @server = server
  end

  def self::inherited( klass )
    parser_name = klass.to_s.sub( /Parser$/, '' ).downcase.intern

    @registry ||= {}
    @registry[ parser_name ] = klass
  end

  def self::registry
    return @registry
  end

  def parse( line )
    raise NotImplementedError,
      "Concrete parsers must implement parse()"
  end

  # dsl-ish helper methods so the parsers don't call server.add_* anymore.  That
  # seems magical now that server isn't be explicitly passed anymore.
  def add_activity( opts = {} )
    @server.add_activity( opts )
  end

  def add_event( opts = {} )
    @server.add_event( opts )
  end
end
