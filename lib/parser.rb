# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

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
end
