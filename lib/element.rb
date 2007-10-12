# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Element
  attr_accessor :wy, :active, :average_size, :right
  attr_reader   :rate, :messages, :name, :activities, :queue, :updates, :average, :total

  def initialize(name, color, type = 0, right = false, start_position = -$TOP)
    @name = name
    @right = right
    @x = (right ? $RIGHT_COL : $LEFT_COL)
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

  def add_activity(message, size, type)
    @pending.push Item.new(message, size, @color, type) if(type != 3)
    @total += 1
    @messages += 1
    @sum += size
    @average = @sum / @total

    if @rate == 0
      @rate = 1.0 / 60
      @messages = 0
    end
  end

  def add_event(message, update_stats)
    @pending.push Item.new(message, 0.01, @color, 2)
    if update_stats
      @total += 1
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
    if @pending.size + @queue.size> 0
      if @pending.size + @queue.size == 1
        @step = rand(1000) * 1.0
      else
        @step = 1.0 / (@queue.size + @pending.size) * 1000.0
      end
      @queue = @queue + @pending
      @pending = []
    else
      @step = 0
    end
    @last_time = glutGet(GLUT_ELAPSED_TIME)
#    @last_time -= @step unless @queue.size == 1
  end

  def print_text(m)
    if $BITMAP_MODE == 0
      begin
        m.each_byte do |c| glutBitmapCharacter(GLUT_BITMAP_8_BY_13, c) end
      rescue RangeError
        $BITMAP_MODE = 1
        m.each_byte do |c| glutBitmapCharacterX(c) end
      end
    else
      m.each_byte do |c| glutBitmapCharacterX(c) end
    end
  end

  def render(options = { })
    @x = (@right ? ($RIGHT_COL - ($COLUMN_SIZE_RIGHT+8)*8.0 / ($WINDOW_WIDTH / 2.0)) : $LEFT_COL)

    d = @wy - @y
    if d.abs < 0.001
      @y = @wy
    else
      @y += d / 20
    end

    glPushMatrix()
    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( @queue.size > 0 ? [10.0, 1.0, 1.0, 1.0] : @color.map { |c| c*3.0} ) )

    glTranslate(@x, @y, @z)
    glRasterPos(0.0, 0.0)

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

    if( $BLOBS[txt].nil? )
      list = glGenLists(1)
      glNewList(list, GL_COMPILE)
      print_text txt
      glEndList()
      $BLOBS[txt] = list
    end

    if( $BLOBS[@name].nil? )
      list = glGenLists(1)
      glNewList(list, GL_COMPILE)
      if @x < 0
        if @name.length > $COLUMN_SIZE_LEFT
          @name = @name[-$COLUMN_SIZE_LEFT..-1]
        end
        print_text( sprintf("%#{$COLUMN_SIZE_LEFT}s ", @name) )
      else
        print_text @name[0..$COLUMN_SIZE_RIGHT-1]
      end


      glEndList()
      $BLOBS[@name] = list
    end

    if @x < 0
      glCallList($BLOBS[@name])
      glCallList($BLOBS[txt])
    else
      glCallList($BLOBS[txt])
      glCallList($BLOBS[@name])
    end

    glPopMatrix()

    t = glutGet(GLUT_ELAPSED_TIME)
    num = 0
    while( (@queue.size > 0) && (@last_time < t ) )
#    if( (@queue.size > 0) && (@last_time < t ) )

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
        a.wx = @x
        a.wy = @y + 0.05
        @activities.push a
      elsif type != 4
        if @x >= 0
          @activities.push Activity.new(url, ($RIGHT_COL - ($COLUMN_SIZE_RIGHT+8)*8.0 / ($WINDOW_WIDTH / 2.0)), @y, @z, color, size, type)
        else
          @activities.push Activity.new(url, ($LEFT_COL + ($COLUMN_SIZE_LEFT+8)*8.0 / ($WINDOW_WIDTH / 2.0) ), @y, @z, color, size, type)
        end
      end
      num += 1
    end
#    @last_time = glutGet(GLUT_ELAPSED_TIME)

    @activities.each do |a|
      if a.x > 1.0 || a.x < -1.0
        @activities.delete a
      else
        a.wy = @y + 0.05 if a.type == 5
        a.render
        $STATS[1] += 1
      end
    end

  end
end
