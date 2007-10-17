# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Element
  attr_accessor :wy, :y, :active, :average_size, :right
  attr_reader   :rate, :messages, :name, :activities, :queue, :updates, :average, :total

  def initialize(name, color, type = 0, right = false, start_position = -$CONFIG.top)

    char_size = 8.0 / ($CONFIG.window_width / 2.0)

    @name = name
    @right = right
    @x = (right ? $CONFIG.right[:alignment] : ($CONFIG.left[:alignment] - char_size * ($CONFIG.left[:size] + 8)))
    @y = start_position
    @z = 0
    @wy = start_position
    @right = right

    @color = color
    @size = 0.01
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
    @type = type

  end

  def add_activity(message, color, size, type)
    @pending.push Item.new(message, size, color, type) if(type != 3)
    @color = color
    @messages += 1
    @sum += size

    if @rate == 0
      @rate = 1.0 / 60
      @messages = 0
    end
  end

  def add_event(message, color, update_stats)
    @pending.push Item.new(message, 0.01, color, 2)
    @color = color
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

  def render(options = { })
    @wx = (@right ? ($CONFIG.right[:alignment] - ($CONFIG.right[:size]+8)*8.0 / ($CONFIG.window_width / 2.0)) : $CONFIG.left[:alignment])

    if(@y == -$CONFIG.top)
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

#    ty = 700 - ((($CONFIG.aspect*2) - (@y+$CONFIG.aspect))/($CONFIG.aspect*2) * $CONFIG.window_height + 0.5).to_i
#    ty2 = 700 - ((($CONFIG.aspect*2) - (@y+$CONFIG.aspect+$CONFIG.line_size))/($CONFIG.aspect*2) * $CONFIG.window_height + 0.5).to_i

#    corrected_y = ((ty2 - ty) == 13) ? @y : (ty+1) / $CONFIG.window_height.to_f * ($CONFIG.aspect * 2) - $CONFIG.aspect

    glTranslate(@x, @y, @z)
    glRasterPos(0.0, 0.0)

    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( @queue.size > 0 ? [10.0, 0.0, 0.0, 10.0] : @color.map { |c| c*10.0} ) )

    if @type == 0
      if @rate < 0.0001
        txt = "    r/m "
      else
        txt = "#{sprintf("%7.2f",@rate * 60)} "
      end
    elsif @type == 1
      if @total == 0
        txt = "  total "
      else
        txt = "#{sprintf("%7d",@total)} "
      end
    elsif @type == 2
      if @average == 0
        txt = "    avg "
      else
        txt = "#{sprintf("%7.2f",@average)} "
      end
    end

   if @x < 0
     str = sprintf("%#{$CONFIG.left[:size]}s %s", @name.length > $CONFIG.left[:size] ? @name[-$CONFIG.left[:size]..-1] : @name, txt)
    else
     str = sprintf("%s %s", txt, @name[0..$CONFIG.right[:size]-1])
    end

    FontStore.render_string(str)

    glPopMatrix()


    t = glutGet(GLUT_ELAPSED_TIME)
    num = 0
    while( (@queue.size > 0) && (@last_time < t ) )

      @last_time += @step
      item = @queue.pop
      url = item.message
      color = item.color
      size = item.size
      type = item.type


      if size < $CONFIG.min_blob_size
        size = $CONFIG.min_blob_size
      elsif size > $CONFIG.max_blob_size
        size = $CONFIG.max_blob_size
      end

      if type == 2
        @activities.push Activity.new(url, 0.0 - (0.013 * url.length), $CONFIG.top, 0.0, color, size, type)
      elsif type == 5
        a = Activity.new(url, 0.0, $CONFIG.top, 0.0, color, size, type)
        a.wx = @wx
        a.wy = @wy + 0.05
        @activities.push a
      elsif type != 4
        if @x >= 0
          @activities.push Activity.new(url, ($CONFIG.right[:alignment] - ($CONFIG.right[:size]+8)*8.0 / ($CONFIG.window_width / 2.0)), @y + $CONFIG.line_size/2, @z, color, size, type)
        else
          @activities.push Activity.new(url, ($CONFIG.left[:alignment] + ($CONFIG.left[:size]+8)*8.0 / ($CONFIG.window_width / 2.0) ), @y + $CONFIG.line_size/2, @z, color, size, type)
        end
      end
      num += 1
    end
#    @last_time = glutGet(GLUT_ELAPSED_TIME)

    @activities.each do |a|
      if a.x > 1.0 || a.x < -1.0 || a.y > $CONFIG.aspect*1.5 || a.y < -($CONFIG.aspect*1.5)
        @activities.delete a
      else
        a.wy = @wy + 0.005 if a.type == 5
        a.render
        $CONFIG.stats[1] += 1
      end
    end

  end
end
