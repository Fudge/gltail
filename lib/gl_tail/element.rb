# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Element
  attr_accessor :wy, :y, :active, :average_size, :right, :color, :name
  attr_reader   :rate, :messages, :activities, :queue, :updates, :average, :total

  def initialize(block, name, color, start_position = nil)
    @block = block

    if name.nil?
      name = ''
    end

    if name =~ /^\d+.\d+.\d+.\d+$/
      @name = Resolver.resolv(name, self)
    else
      @name = name
    end

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
    @color = color || [1.0, 1.0, 1.0, 1.0]
    @type = (@block.activity_type == "blobs" ? :blobs : :bars)
    @bar_color ||= @color.dup
    @text_list   = nil
    @number_list = nil
    @last_text   = nil
    @last_number = nil
  end

  def add_activity(message, color, size,  type, real_size)
    @bar_color[0] = @bar_color[0] + (@color[0] - @bar_color[0]) / 5
    @bar_color[1] = @bar_color[1] + (@color[1] - @bar_color[1]) / 5
    @bar_color[2] = @bar_color[2] + (@color[2] - @bar_color[2]) / 5

    @pending.push Item.new(message, size, color, type) if(type != 3)
    @messages += 1
    @total += 1
    @sum += real_size
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
      @total += 1
      if @rate == 0
        @rate = 1.0 / 60
        @messages = 0
      end
    end
  end


  def update
    @rate = (@rate * 299.0 + @messages) / 300.0
    @updates += 1
    @messages = 0
    size = @pending.size
    if size > 0
      @average = @sum / @total.to_f

      @step = 1.0 / size * 1000.0
      @queue = @pending
      if size == 1
        @step = rand(1000) * 1.0
      end
      @pending = []
    else
      @step = 0
    end
    @last_time = glutGet(GLUT_ELAPSED_TIME)
    @last_time += @step if @queue.size == 1
    @rate
  end

  def render_events(engine)
    @color ||= [1.0, 1.0, 1.0, 1.0]

    t = glutGet(GLUT_ELAPSED_TIME)
    @queue.clear
#    while( (item = @queue.pop) && (@last_time < t ) )

#      @last_time += @step
#      item = @queue.pop

#    end

    @delete = []
    cutoff = -(engine.screen.aspect * 1.5)
    for a in @activities do 
      if a.x > 1.0 || a.x < -1.0 || a.y < cutoff
        if a.body 
          engine.space.remove_body(a.body)
          engine.space.remove_shape(a.shape)
          a.free_vertex_lists
        end 
        @delete <<  a
      else
        a.wy = @wy + 0.005 if(a.type == 5 && @wy != a.wy)
        a.render(engine)
        engine.stats[1] += 1
      end
    end
    
    @activities = @activities - @delete

  end

  def render(engine, options = { })

    @is_right ||= @block.is_right

    @block_width ||= @block.width
    @block_width_times_8 ||= @block_width * 8

    # this used to be in the constructor, couldnt leave it there without using globals
    if not defined? @x 
      @x = (@is_right ? @block.alignment : (@block.alignment - (8.0 / (@block.config.screen.window_width / 2.0)) * (@block_width + 8)))
      @y = @start_position
      @z = 0
      @wy = @start_position

      @color = @block.color.dup if @color.nil? && @block.color
      @color ||= [1.0, 1.0, 1.0, 1.0]
      @size = 0.01


    end

    if @wx.nil?
      @wx = @is_right ? (@block.alignment - (@block_width_times_8+64.0) / (engine.screen.window_width / 2.0)) : @block.alignment
    end 

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

    glBegin(GL_QUADS)

    if @x >= 0
      y2 = 0.0
      @x1 = 7*8.0 / (engine.screen.window_width / 2.0)
      y1 = engine.screen.line_size * 0.9
      x2 = @x1 + ((@block_width_times_8+8.0) / (engine.screen.window_width / 2.0) ) * (rate / @block.max_rate)
      
      @x2 ||= @x1
      d = (@x2 - x2)
      if d.abs < 0.001
        @x2 = x2
      else
        @x2 -= d / 40
      end
      glColor(@bar_color)
      glVertex3f(@x1, y1, @z)
      glColor(@bar_color)
      glVertex3f(@x2, y1, @z)
      glColor([0.0, 0.0, 0.0, 0.0])
      glVertex3f(@x2, y2, @z)
      glColor(@bar_color)
      glVertex3f(@x1, y2, @z)
    else
      @x2 = (@block_width_times_8+8) / (engine.screen.window_width / 2.0)
      y2  = 0.0
      y1  = engine.screen.line_size * 0.9
      x1 = ((@block_width_times_8+8) / (engine.screen.window_width / 2.0) ) * (1.0 - rate / @block.max_rate)
      
      @x1 ||= @x2
      d = (@x1 - x1)
      if d.abs < 0.001
        @x1 = x1
      else
        @x1 -= d / 20
      end
      
      glColor(@bar_color)
      glVertex3f(@x1, y1, @z)
      glColor(@bar_color)
      glVertex3f(@x2, y1, @z)
      glColor(@bar_color)
      glVertex3f(@x2, y2, @z)
      glColor([0.0, 0.0, 0.0, 0.0])
      glVertex3f(@x1, y2, @z)
      
    end
    glEnd

    glColor( (@queue.size > 0 ? (engine.screen.highlight_color || [1.0, 0.0, 0.0, 1.0]) : @color ) )

    case @block.show
    when 0
      if @rate == 0
        txt = "     r/m "
      else
        txt = "#{sprintf("%8.2f",@rate * 60)} "
      end
    when 1
      if @total == 0
        txt = "   total "
      else
        txt = "#{sprintf("%8d",@total)} "
      end
    when 2
      if @average == 0
        txt = "     avg "
      else
        txt = "#{sprintf("%8.2f",@average)} "
      end
    else
      raise "unknown block type #{self.inspect}"
    end

    if @x < 0
      text = sprintf("%#{@block_width}s", @name.length > @block_width ? @name[-@block_width..-1] : @name)

      if text != @last_text
        glDeleteLists(@text_list,1)
        @text_list = nil
      end 
     
      if txt != @last_number
        @number_list = nil
      else 
        BlobStore.mark(txt)
      end 

      @text_list ||= engine.render_string(text, false, 1) 
      @number_list ||= engine.render_string(txt, true, text.length)

      @last_text = text
      @last_number = txt

      glCallList(@text_list)
      glCallList(@number_list)

    else
      txt = txt[1..-1]
      text = @name[0..@block_width-1]
      if text != @last_text
        glDeleteLists(@text_list,1)
        @text_list = nil
      end 

      if txt != @last_number
        @number_list = nil
      else 
        BlobStore.mark(txt)
      end 

      @text_list ||= engine.render_string(text, false, txt.length)
      @number_list ||= engine.render_string(txt, true)

      @last_text = text
      @last_number = txt

      glCallList(@number_list)
      glCallList(@text_list)
    end

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
        a = Activity.new(url, 0.0 - (0.008 * url.length), engine.screen.top, 0.0, color, size, type)
        @activities.push a

      elsif type == 5
        a = Activity.new(url, 0.0, engine.screen.top, 0.0, color, size, type)
        a.wx = @wx
        a.wy = @wy + 0.05
        @activities.push a
      elsif type != 4
        if @x >= 0
          a =  Activity.new(url, (@block.alignment - (@block_width_times_8+64) / (engine.screen.window_width / 2.0)), @y + engine.screen.line_size/2, @z, color, size, type)
        else
          a =  Activity.new(url, (@block.alignment + (@block_width_times_8+64) / (engine.screen.window_width / 2.0) ), @y + engine.screen.line_size/2, @z, color, size, type)
        end
        @activities.push a

        bs = (size + 0.0005) * engine.screen.window_width * engine.screen.aspect 

        if $PHYSICS
          a.body =  CP::Body.new(0.0001, 0.0001)
          a.body.m = bs * 5.5
          a.body.p = CP::Vec2.new(a.x * engine.screen.window_width * engine.screen.aspect, a.y * engine.screen.window_height)
          if a.x < 0.0 
            a.body.v = CP::Vec2.new(250,0)
          else 
            a.body.v = CP::Vec2.new(-250,0)
          end 
          a.shape = CP::Shape::Circle.new(a.body, bs, CP::Vec2.new(0.0, 0.0))
          a.shape.e = 0.9
          a.shape.u = 1

          engine.space.add_body(a.body)
          engine.space.add_shape(a.shape)
        end
      end 
    end

    @delete = []
    for a in @activities do
      if a.body
        if a.x > 1.0 || a.x < -1.0 || a.y < -(engine.screen.aspect*1.5)
          engine.space.remove_body(a.body)
          engine.space.remove_shape(a.shape)
          @delete << a
          a.free_vertex_lists
        else 
          a.render(engine)
          engine.stats[1] += 1
        end 
        
      elsif a.x > 1.0 || a.x < -1.0 || a.y < -(engine.screen.aspect*1.5)
        @activities.delete a
      else
        a.wy = @wy + 0.005 if(a.type == 5 && @wy != a.wy)
        a.render(engine)
        engine.stats[1] += 1
      end
    end

    @activities = @activities - @delete

    @bar_color[0] = @bar_color[0] + (0.15 - @bar_color[0]) / 100
    @bar_color[1] = @bar_color[1] + (0.15 - @bar_color[1]) / 100
    @bar_color[2] = @bar_color[2] + (0.15 - @bar_color[2]) / 100

  end

  def <=>(b)
    b.rate <=> self.rate
  end

  def > (b)
    b.rate > self.rate
  end

  def < (b)
    b.rate < self.rate
  end

  def <= (b)
    b.rate <= self.rate
  end

  def >= (b)
    b.rate >= self.rate
  end

  def free_vertex_lists
    unless @text_list.nil?
      glDeleteLists(@text_list, 1)
      @text_list = nil
    end 
    @number_list = nil
  end 

  def reshape
    free_vertex_lists

    @last_text   = nil
    @last_number = nil

    @is_right = nil

    @block_width = nil 
    @block_width_times_8 = nil

    @wx = nil

    @activities.each do |a|
      a.reshape
    end 
  end 


end
