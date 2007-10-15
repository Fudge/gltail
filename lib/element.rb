# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Element
  attr_accessor :wy, :y, :active, :average_size, :right
  attr_reader   :rate, :messages, :name, :activities, :queue, :updates, :average, :total

  def initialize(name, color, type = 0, right = false, start_position = -$TOP)

    char_size = 8.0 / ($WINDOW_WIDTH / 2.0)

    @name = name
    @right = right
    @x = (right ? $RIGHT_COL : ($LEFT_COL - char_size * ($COLUMN_SIZE_LEFT + 8)))
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

    texture_width = (right ? $COLUMN_SIZE_RIGHT + 8 : $COLUMN_SIZE_LEFT + 8) * 8
    texture_height = 16
    @texture = glGenTextures(1)[0]
    @texture_data = "\x00" * texture_width * texture_height * 3
    glBindTexture(GL_TEXTURE_2D, @texture)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 8, 16, 0, GL_RGB, GL_UNSIGNED_BYTE, @texture_data)
  end

  def add_activity(message, size, type)
    @pending.push Item.new(message, size, @color, type) if(type != 3)
    @messages += 1
    @sum += size

    if @rate == 0
      @rate = 1.0 / 60
      @messages = 0
    end
  end

  def add_event(message, update_stats)
    @pending.push Item.new(message, 0.01, @color, 2)
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
    @wx = (@right ? ($RIGHT_COL - ($COLUMN_SIZE_RIGHT+8)*8.0 / ($WINDOW_WIDTH / 2.0)) : $LEFT_COL)

    if(@y == -$TOP)
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

#    ty = 700 - ((($ASPECT*2) - (@y+$ASPECT))/($ASPECT*2) * $WINDOW_HEIGHT + 0.5).to_i
#    ty2 = 700 - ((($ASPECT*2) - (@y+$ASPECT+$LINE_SIZE))/($ASPECT*2) * $WINDOW_HEIGHT + 0.5).to_i

#    corrected_y = ((ty2 - ty) == 13) ? @y : (ty+1) / $WINDOW_HEIGHT.to_f * ($ASPECT * 2) - $ASPECT

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
     str = sprintf("%#{$COLUMN_SIZE_LEFT}s %s", @name.length > $COLUMN_SIZE_LEFT ? @name[-$COLUMN_SIZE_LEFT..-1] : @name, txt)
    else
     str = sprintf("%s %s", txt, @name[0..$COLUMN_SIZE_RIGHT-1])
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


      if size < $MIN_BLOB_SIZE
        size = $MIN_BLOB_SIZE
      elsif size > $MAX_BLOB_SIZE
        size = $MAX_BLOB_SIZE
      end

      if type == 2
        @activities.push Activity.new(url, 0.0 - (0.013 * url.length), $TOP, 0.0, color, size, type)
      elsif type == 5
        a = Activity.new(url, 0.0, $TOP, 0.0, color, size, type)
        a.wx = @wx
        a.wy = @wy + 0.05
        @activities.push a
      elsif type != 4
        if @x >= 0
          @activities.push Activity.new(url, ($RIGHT_COL - ($COLUMN_SIZE_RIGHT+8)*8.0 / ($WINDOW_WIDTH / 2.0)), @y + $LINE_SIZE/2, @z, color, size, type)
        else
          @activities.push Activity.new(url, ($LEFT_COL + ($COLUMN_SIZE_LEFT+8)*8.0 / ($WINDOW_WIDTH / 2.0) ), @y + $LINE_SIZE/2, @z, color, size, type)
        end
      end
      num += 1
    end
#    @last_time = glutGet(GLUT_ELAPSED_TIME)

    @activities.each do |a|
      if a.x > 1.0 || a.x < -1.0 || a.y > $ASPECT*1.5 || a.y < -($ASPECT*1.5)
        @activities.delete a
      else
        a.wy = @wy + 0.005 if a.type == 5
        a.render
        $STATS[1] += 1
      end
    end

  end
end
