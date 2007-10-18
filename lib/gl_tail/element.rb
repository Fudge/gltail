# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Element
  attr_accessor :wy, :y, :active, :average_size, :right, :color
  attr_reader   :rate, :messages, :name, :activities, :queue, :updates, :average, :total

  def initialize(block, name, start_position = nil)
    @block = block
    @name = name

    @start_position = start_position.nil? ? -@block.top : start_position

    @queue = []
    @pending = []
    @activities = []
    @messages = 0
    @rate = 0
    @total = 0
    @sum = 0
    @average = 0.0
    @last_time = 0
    @step = 0, @updates = 0
    @active = false
  end

  def add_activity(message, color, size,  type)
    @pending.push Item.new(message, size, color, type) if(type != 3)
    @messages += 1
    @sum += size
    @color = color

    if @rate == 0
      @rate = 1.0 / 60
      @messages = 0
    end
  end

  def add_event(message, color, update_stats)
    @pending.push Item.new(message, 0.01, color, 2)
    if update_stats
      @messages += 1
      if @rate == 0
        @rate = 1.0 / 60
        @messages = 0
      end
    end
  end


  def update
    @active = true if @total > 0
    @updates += 1
    @rate = (@rate.to_f * 299 + @messages) / 300
    @messages = 0
    if @pending.size + @queue.size > 0
      @total += @pending.size
      @average = @sum / @total

      @step = 1.0 / (@queue.size + @pending.size) * 1000.0
      @queue = @queue + @pending
      if @queue.size == 1
        @step = rand(1000) * 1.0
      end
      @pending = []
    else
      @step = 0
    end
    @last_time = glutGet(GLUT_ELAPSED_TIME)
    @last_time += @step if @queue.size == 1
#    @last_time -= @step if @queue.size != 1

    if @name =~ /^\d+.\d+.\d+.\d+$/
      @name = Resolver.resolv(@name)
    end
  end

  def render(engine, options = { })
    
    # this used to be in the constructor, couldnt leave it there without using globals
    if not defined? @x
      @x = (@block.is_right ? @block.alignment : (@block.alignment - (8.0 / (@block.config.screen.window_width / 2.0)) * (@block.width + 8)))
      @y = @start_position
      @z = 0
      @wy = @start_position
    
      @color = @block.color.dup # FIXME: each element starts out with the color of the containing block
      @size = 0.01    
    end
    
    @wx = @block.is_right ? (@block.alignment - (@block.width+8)*8.0 / (engine.screen.window_width / 2.0)) : @block.alignment

    if(@y == -@block.top)
      @y = @wy
    end

    d = @wy - @y
    if d.abs < 0.001
      @y = @wy
    else
      @y += d / 20
    end

    d = @wx - @x
    if d.abs < 0.001
      @x = @wx
    else
      @x += d / 20
    end

    glPushMatrix()

    glTranslate(@x, @y, @z)
     
    glColor( (@queue.size > 0 ? (engine.screen.highlight_color || [1.0, 0.0, 0.0, 1.0]) : @color ) )

    case @block.show
    when 0
      if @rate < 0.0001
        txt = "    r/m "
      else
        txt = "#{sprintf("%7.2f",@rate * 60)} "
      end
    when 1
      if @total == 0
        txt = "  total "
      else
        txt = "#{sprintf("%7d",@total)} "
      end
    when 2
      if @average == 0
        txt = "    avg "
      else
        txt = "#{sprintf("%7.2f",@average)} "
      end
    else
      raise "unknown block type #{self.inspect}"
    end

   if @x < 0
     str = sprintf("%#{@block.width}s %s", @name.length > @block.width ? @name[-@block.width..-1] : @name, txt)
    else
     str = sprintf("%s %s", txt, @name[0..@block.width-1])
    end

    engine.render_string(str)

    glPopMatrix()

    t = glutGet(GLUT_ELAPSED_TIME)
    while( (@queue.size > 0) && (@last_time < t ) )

      @last_time += @step
      item = @queue.pop
      url = item.message
      color = item.color
      size = item.size
      type = item.type

      if type == 2
        @activities.push Activity.new(url, 0.0 - (0.013 * url.length), engine.screen.top, 0.0, color, size, type)
      elsif type == 5
        a = Activity.new(url, 0.0, engine.screen.top, 0.0, color, size, type)
        a.wx = @wx
        a.wy = @wy + 0.05
        @activities.push a
      elsif type != 4
        if @x >= 0
          @activities.push Activity.new(url, (@block.alignment - (@block.width+8)*8.0 / (engine.screen.window_width / 2.0)), @y + engine.screen.line_size/2, @z, color, size, type)
        else
          @activities.push Activity.new(url, (@block.alignment + (@block.width+8)*8.0 / (engine.screen.window_width / 2.0) ), @y + engine.screen.line_size/2, @z, color, size, type)
        end
      end
    end

    @activities.each do |a|
      if a.x > 1.0 || a.x < -1.0 || a.y < -(engine.screen.aspect*1.5)
        @activities.delete a
      else
        a.wy = @wy + 0.005 if(a.type == 5 && @wy != a.wy)
        a.render(engine)
        engine.stats[1] += 1
      end
    end

  end
end
