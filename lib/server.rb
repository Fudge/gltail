# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Server
  attr_reader :name, :host, :color, :parser

  def initialize(options)
    @name = options[:name] || options[:host]
    @host = options[:host]
    @color = options[:color] || [1.0, 1.0, 1.0, 1.0]
    @parser = Parser.registry[ options[:parser] ] || Parser.registry[ :apache ]
    @blocks = options[:blocks]

    # instantiate the parser
    @parser = @parser.new( self )

  end

  #block, message, size
  def add_activity(options = { })
    block = @blocks[options[:block]].add_activity( { :name => @name, :color => @color, :size => $CONFIG.min_blob_size }.update(options) ) if (options[:block] && @blocks[options[:block]])
  end

  #block, message
  def add_event(options = { })
    block = @blocks[options[:block]].add_event( { :name => @name, :color => @color, :size => $CONFIG.min_blob_size}.update(options) ) if (options[:block] && @blocks[options[:block]])
  end

end
