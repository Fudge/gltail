
module GlTail
  CONFIG_OPTIONS = { }

  COLORS = {
      'maroon' => %w{ 128 0 0 255 },
      'dark red' => %w{ 139 0 0 255 },
      'brown' => %w{ 165 42 42 255 },
      'firebrick' => %w{ 178 34 34 255 },
      'crimson' => %w{ 220 20 60 255 },
      'red' => %w{ 255 0 0 255 },
      'tomato' => %w{ 255 99 71 255 },
      'coral' => %w{ 255 127 80 255 },
      'indian red' => %w{ 205 92 92 255 },
      'light coral' => %w{ 240 128 128 255 },
      'dark salmon' => %w{ 233 150 122 255 },
      'salmon' => %w{ 250 128 114 255 },
      'light salmon' => %w{ 255 160 122 255 },
      'orange red' => %w{ 255 69 0 255 },
      'dark orange' => %w{ 255 140 0 255 },
      'orange' => %w{ 255 165 0 255 },
      'gold' => %w{ 255 215 0 255 },
      'dark golden rod' => %w{ 184 134 11 255 },
      'golden rod' => %w{ 218 165 32 255 },
      'pale golden rod' => %w{ 238 232 170 255 },
      'dark khaki' => %w{ 189 183 107 255 },
      'khaki' => %w{ 240 230 140 255 },
      'olive' => %w{ 128 128 0 255 },
      'yellow' => %w{ 255 255 0 255 },
      'yellow green' => %w{ 154 205 50 255 },
      'dark olive green' => %w{ 85 107 47 255 },
      'olive drab' => %w{ 107 142 35 255 },
      'lawn green' => %w{ 124 252 0 255 },
      'chart reuse' => %w{ 127 255 0 255 },
      'green yellow' => %w{ 173 255 47 255 },
      'dark green' => %w{ 0 100 0 255 },
      'green' => %w{ 0 128 0 255 },
      'forest green' => %w{ 34 139 34 255 },
      'lime' => %w{ 0 255 0 255 },
      'lime green' => %w{ 50 205 50 255 },
      'light green' => %w{ 144 238 144 255 },
      'pale green' => %w{ 152 251 152 255 },
      'dark sea green' => %w{ 143 188 143 255 },
      'medium spring green' => %w{ 0 250 154 255 },
      'spring green' => %w{ 0 255 127 255 },
      'sea green' => %w{ 46 139 87 255 },
      'medium aqua marine' => %w{ 102 205 170 255 },
      'medium sea green' => %w{ 60 179 113 255 },
      'light sea green' => %w{ 32 178 170 255 },
      'dark slate gray' => %w{ 47 79 79 255 },
      'teal' => %w{ 0 128 128 255 },
      'dark cyan' => %w{ 0 139 139 255 },
      'aqua' => %w{ 0 255 255 255 },
      'cyan' => %w{ 0 255 255 255 },
      'light cyan' => %w{ 224 255 255 255 },
      'dark turquoise' => %w{ 0 206 209 255 },
      'turquoise' => %w{ 64 224 208 255 },
      'medium turquoise' => %w{ 72 209 204 255 },
      'pale turquoise' => %w{ 175 238 238 255 },
      'aqua marine' => %w{ 127 255 212 255 },
      'powder blue' => %w{ 176 224 230 255 },
      'cadet blue' => %w{ 95 158 160 255 },
      'steel blue' => %w{ 70 130 180 255 },
      'corn flower blue' => %w{ 100 149 237 255 },
      'deep sky blue' => %w{ 0 191 255 255 },
      'dodger blue' => %w{ 30 144 255 255 },
      'light blue' => %w{ 173 216 230 255 },
      'sky blue' => %w{ 135 206 235 255 },
      'light sky blue' => %w{ 135 206 250 255 },
      'midnight blue' => %w{ 25 25 112 255 },
      'navy' => %w{ 0 0 128 255 },
      'dark blue' => %w{ 0 0 139 255 },
      'medium blue' => %w{ 0 0 205 255 },
      'blue' => %w{ 0 0 255 255 },
      'royal blue' => %w{ 65 105 225 255 },
      'blue violet' => %w{ 138 43 226 255 },
      'indigo' => %w{ 75 0 130 255 },
      'dark slate blue' => %w{ 72 61 139 255 },
      'slate blue' => %w{ 106 90 205 255 },
      'medium slate blue' => %w{ 123 104 238 255 },
      'medium purple' => %w{ 147 112 219 255 },
      'dark magenta' => %w{ 139 0 139 255 },
      'dark violet' => %w{ 148 0 211 255 },
      'dark orchid' => %w{ 153 50 204 255 },
      'medium orchid' => %w{ 186 85 211 255 },
      'purple' => %w{ 128 0 128 255 },
      'thistle' => %w{ 216 191 216 255 },
      'plum' => %w{ 221 160 221 255 },
      'violet' => %w{ 238 130 238 255 },
      'magenta' => %w{ 255 0 255 255 },
      'fuchsia' => %w{ 255 0 255 255 },
      'orchid' => %w{ 218 112 214 255 },
      'medium violet red' => %w{ 199 21 133 255 },
      'pale violet red' => %w{ 219 112 147 255 },
      'deep pink' => %w{ 255 20 147 255 },
      'hot pink' => %w{ 255 105 180 255 },
      'light pink' => %w{ 255 182 193 255 },
      'pink' => %w{ 255 192 203 255 },
      'antique white' => %w{ 250 235 215 255 },
      'beige' => %w{ 245 245 220 255 },
      'bisque' => %w{ 255 228 196 255 },
      'blanched almond' => %w{ 255 235 205 255 },
      'wheat' => %w{ 245 222 179 255 },
      'corn silk' => %w{ 255 248 220 255 },
      'lemon chiffon' => %w{ 255 250 205 255 },
      'light golden rod yellow' => %w{ 250 250 210 255 },
      'light yellow' => %w{ 255 255 224 255 },
      'saddle brown' => %w{ 139 69 19 255 },
      'sienna' => %w{ 160 82 45 255 },
      'chocolate' => %w{ 210 105 30 255 },
      'peru' => %w{ 205 133 63 255 },
      'sandy brown' => %w{ 244 164 96 255 },
      'burly wood' => %w{ 222 184 135 255 },
      'tan' => %w{ 210 180 140 255 },
      'rosy brown' => %w{ 188 143 143 255 },
      'moccasin' => %w{ 255 228 181 255 },
      'navajo white' => %w{ 255 222 173 255 },
      'peach puff' => %w{ 255 218 185 255 },
      'misty rose' => %w{ 255 228 225 255 },
      'lavender blush' => %w{ 255 240 245 255 },
      'linen' => %w{ 250 240 230 255 },
      'old lace' => %w{ 253 245 230 255 },
      'papaya whip' => %w{ 255 239 213 255 },
      'sea shell' => %w{ 255 245 238 255 },
      'mint cream' => %w{ 245 255 250 255 },
      'slate gray' => %w{ 112 128 144 255 },
      'light slate gray' => %w{ 119 136 153 255 },
      'light steel blue' => %w{ 176 196 222 255 },
      'lavender' => %w{ 230 230 250 255 },
      'floral white' => %w{ 255 250 240 255 },
      'alice blue' => %w{ 240 248 255 255 },
      'ghost white' => %w{ 248 248 255 255 },
      'honeydew' => %w{ 240 255 240 255 },
      'ivory' => %w{ 255 255 240 255 },
      'azure' => %w{ 240 255 255 255 },
      'snow' => %w{ 255 250 250 255 },
      'black' => %w{ 0 0 0 255 },
      'dim gray' => %w{ 105 105 105 255 },
      'dim grey' => %w{ 105 105 105 255 },
      'gray' => %w{ 128 128 128 255 },
      'grey' => %w{ 128 128 128 255 },
      'dark gray' => %w{ 169 169 169 255 },
      'dark grey' => %w{ 169 169 169 255 },
      'silver' => %w{ 192 192 192 255 },
      'light gray' => %w{ 211 211 211 255 },
      'light grey' => %w{ 211 211 211 255 },
      'gainsboro' => %w{ 220 220 220 255 },
      'white smoke' => %w{ 245 245 245 255 },
      'white' => %w{ 255 255 255 255 }
  }

  class Screen
    include Configurable

    config_attribute :wanted_fps, "FIXME: add description"

    config_attribute :min_blob_size, "Minimum size of activity indicators [0.0 - 1.0]"
    config_attribute :max_blob_size, "Maximum size of activity indicators [0.0 - 1.0]"

    # shortcut to set these via dimensions
    config_attribute :window_width, "Width of GlTail window"
    config_attribute :window_height, "Height of GlTail window"

    config_attribute :fullscreen, "should glTail start in fullscren?"

    config_attribute :mode, "FIXME"
    config_attribute :bounce, "FIXME"

    config_attribute :highlight_color, "FIXME: add description", :type => :color

    attr_accessor :aspect, :line_size, :top, :bitmap_mode

    def initialize(config)
      @config = config

      @fullscreen = false
            
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
      @blocks.sort! {|k,v| k.order <=> v.order}
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
      if @blocks_by_name[options[:block]]
        size = screen.min_blob_size
        if options[:size]
          size = options[:size].to_f
          options[:real_size] = size
          @max_size = size if size > @max_size
          options[:size] = screen.min_blob_size + ((size / @max_size) * (screen.max_blob_size - screen.min_blob_size))
        end
        @blocks_by_name[options[:block]].add_activity({ :name => source.name,
                                                        :color => source.color,
                                                        :size => size
                                                      }.update(options) )
      end
    end

    #block, message
    def add_event(source, options = { })
      if @blocks_by_name[options[:block]]
        @blocks_by_name[options[:block]].add_event( { :name => source.name, :color => source.color, :size => screen.min_blob_size}.update(options) )
      end
    end
  end
end
