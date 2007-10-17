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
    @max_size = 1.0

    # instantiate the parser
    @parser = @parser.new( self )

  end

  #block, message, size
  def add_activity(options = { })
    size = $CONFIG.min_blob_size
    if options[:size]
      size = options[:size].to_f
      @max_size = size if size > @max_size
      size = $CONFIG.min_blob_size + ((size / @max_size) * ($CONFIG.max_blob_size - $CONFIG.min_blob_size))
      options[:size] = size
    end

    block = @blocks[options[:block]].add_activity( { :name => @name, :color => @color, :size => $CONFIG.min_blob_size }.update(options) ) if (options[:block] && @blocks[options[:block]])
  end

  #block, message
  def add_event(options = { })
    block = @blocks[options[:block]].add_event( { :name => @name, :color => @color, :size => $CONFIG.min_blob_size}.update(options) ) if (options[:block] && @blocks[options[:block]])
  end

  def update
    @max_size = @max_size * 0.99 if(@max_size * 0.99 > 1.0)
  end

end
