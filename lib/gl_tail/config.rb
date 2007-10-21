
module GlTail
  CONFIG_OPTIONS = { }

  COLORS = {
    'white'   => %w{ 255 255 255 255 },
    'red'     => %w{ 255   0   0 255 },
    'green'   => %w{   0 255   0 255 },
    'blue'    => %w{   0   0 255 255 },
    'yellow'  => %w{ 255 255   0 255 },
    'cyan'    => %w{   0 255 255 255 },
    'magenta' => %w{ 255   0 255 255 },

    'purple'  => %w{ 128   0 255 255 },
    'orange'  => %w{ 255 128   0 255 },
    'pink'    => %w{ 255   0 128 255 },
  }

  class Screen
    include Configurable

    config_attribute :wanted_fps, "FIXME: add description"

    config_attribute :min_blob_size, "Minimum size of activity indicators [0.0 - 1.0]"
    config_attribute :max_blob_size, "Maximum size of activity indicators [0.0 - 1.0]"

    # shortcut to set these via dimensions
    config_attribute :window_width, "Width of GlTail window"
    config_attribute :window_height, "Height of GlTail window"

    config_attribute :mode, "FIXME"
    config_attribute :bounce, "FIXME"

    config_attribute :highlight_color, "FIXME: add description", :type => :color

    attr_accessor :aspect, :line_size, :top, :bitmap_mode

    def initialize(config)
      @config = config

      @wanted_fps = 0
      @aspect = 0.6
      @bounce = false

      @top = 0.9
      @line_size = 0.03
      @bitmap_mode = 0
      @mode = 0
      @highlight_color = [1.0, 0.0, 0.0, 1.0]
    end

    def set_dim(x, y)
      self.window_width = x.to_i
      self.window_height = y.to_i
    end


    def dimensions=(dim)
      if dim.is_a?(String)
        case dim
        when /^(\d+)x(\d+)$/
          set_dim $1, $2
        when /^(\d+), (\d+)$/
          set_dim $1, $2
        else
          raise "dimensions not understood #{dim}, please use <width>x<height> or <width>, <height>"
        end
      else
        raise "what are you #{dim.inspect}"
      end
    end

    def right
      @right ||= Column.new(@config, :right)
    end

    def left
      @left ||= Column.new(@config, :left)
    end

  end

  class Column
    include Configurable

    config_attribute :size, "FIXME: add description"
    config_attribute :alignment, "FIXME: add description"

    def initialize(config, which)
      @config = config
      @which = which
    end

    def is_right
      @which == :right
    end
  end

  class Config
    class << self
      def parse_yaml(file)
        require 'yaml'

        YamlParser.new(file).apply(self.new)
      end
    end

    attr_reader :sources

    def initialize
      @sources = []
      @blocks = []
      @max_size = 1.0
    end

    def screen
      @screen ||= Screen.new(self)
    end

    def blocks
      @blocks
    end

    def add_block(name)
      @blocks << b = Block.new(self, name)
      b
    end

    def reshape(w, h)
      screen.aspect = h.to_f / w.to_f
      screen.window_width, screen.window_height = w, h
    end

    def do_process
      active = 0

      sources.each do |it|
        active += 1
        it.process
      end

      active
    end

    def update
      sources.each { |it| it.update }
      blocks.each { |it| it.update }
      @max_size = @max_size * 0.99 if(@max_size * 0.99 > 1.0)
    end

    def init
      sources.each { |it| it.init }

      @blocks_by_name = {}

      blocks.each do |it|
        @blocks_by_name[it.name] = it
      end
    end

    #block, message, size
    def add_activity(source, options = { })
      size = screen.min_blob_size
      if options[:size]
        size = options[:size].to_f
        @max_size = size if size > @max_size
        size = screen.min_blob_size + ((size / @max_size) * (screen.max_blob_size - screen.min_blob_size))
        options[:size] = size
      end

      if block = @blocks_by_name[options[:block]]
        block.add_activity({
          :name => source.name,
          :color => source.color,
          :size => screen.min_blob_size
          }.update(options) )
      end
    end

    #block, message
    def add_event(source, options = { })
      if block = @blocks_by_name[options[:block]]
        block.add_event( { :name => source.name, :color => source.color, :size => screen.min_blob_size}.update(options) )
      end
    end
  end
end
