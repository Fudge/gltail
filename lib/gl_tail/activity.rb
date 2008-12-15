# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Activity
  attr_accessor :x, :y, :z, :wx, :wy, :wz, :xi, :yi, :zi
  attr_accessor :message, :color, :size, :type, :body, :shape, :gl_list

  def initialize(message, x, y, z, color, size, type = 0)
    @shape = @body = nil
    @message = message
    @x, @y, @z = x, y, z
#    @xi, @yi, @zi = 0.012 + (rand(100)/100.0 ) * 0.0012 , 0.002 + (rand(1000)/1000.0 ) * 0.002, 0
    @xi, @yi, @zi = 0.006 , 0.0013, 0

    if @x >= 0.0
      @xi = -@xi
    end

    @xi = (rand(100)/100.0 * 0.002) - 0.001 if type == 2
    @yi = (rand(100)/100.0 * 0.002) - 0.001 if type == 2

    @color = color
    @size  = size
    @type  = type

    @rx, @ry, @rz = rand(360), rand(360), 0
    @gl_list     = nil
    @text_list   = nil
  end

  def render(engine)

    @screen_width  ||= engine.screen.window_width * engine.screen.aspect
    @screen_height ||= engine.screen.window_height
    @top ||= engine.screen.top

    unless @body
      if @type != 5
        @x += @xi
        @y += @yi
        @yi = @yi - 0.00008

#      @yi = @yi * 1.01
#      @xi = @xi * 0.9995

#        if @y - @size/2 < -@top
#          @y = -@top + @size/2
#          @yi = -@yi * 0.7
#        end
      else
        dy = @wy - @y
        if dy.abs < 0.001
          @y = @wy
        else
          @y += dy / 20
        end
        
        dx = @wx - @x
        if dx.abs < 0.001
          @x = @wx
        else
          @x += dx / 20
        end

        if @x == @wx
          @x = 20.0
        end

      end
    else 
      p = body.p
      @x = p.x / @screen_width
      @y = p.y / @screen_height
    end 

    glPushMatrix()
    glColor(@color)

    if @type == 0 || @type == 5
      if @gl_list.nil?
        @gl_list = BlobStore.get((@size * 1000).to_i)
        if @gl_list.nil?
          @gl_list = glGenLists(1)
          glNewList(@gl_list, GL_COMPILE)
          glEnable(GL_LINE_SMOOTH)
          glBegin(GL_LINE_STRIP)
          r = @size

          angle = 0.0
          while angle < 6.28318530717959 do
            glVertex3f(r * Math::sin(angle), r * Math::cos(angle), 0.0)
            angle += 0.392699081698724
          end 
          glVertex3f(0, r, 0.0)
          glEnd
          glDisable(GL_LINE_SMOOTH);

          glEndList()
          BlobStore.put((@size * 1000).to_i, @gl_list)
        end
      end 
      glTranslate(@x,@y,@z)
      glCallList(@gl_list)
    elsif @type == 1
      glTranslate(@x, @y, @z)
      glRotatef(@rx, 1.0, 0.0, 0.0)
      glRotatef(@ry, 0.0, 1.0, 0.0)
      @rx += 2
      @ry += 1
      unless BlobStore.has(@size.to_s)
        list = glGenLists(1)
        glNewList(list, GL_COMPILE)

        glBegin(GL_QUADS)
        glVertex3f(-@size,  @size, 0)
        glVertex3f( @size,  @size, 0)
        glVertex3f( @size, -@size, 0)
        glVertex3f(-@size, -@size, 0)
        glEnd

        glEndList()
        BlobStore.put(@size.to_s,list)
      end

      glCallList(BlobStore.get(@size.to_s))
    elsif @type == 2
      glTranslate(@x, @y, @z)
      glRasterPos(0.0, 0.0)

      @text_list ||= engine.render_string(@message, false)

      glCallList(@text_list)

    end

    glPopMatrix()
  end

  def free_vertex_lists
    unless @text_list.nil?
      glDeleteLists(@text_list, 1)
      @text_list = nil
    end 
  end 

  def reshape
    free_vertex_lists
    
    @gl_list = nil
    @screen_width  = nil
    @screen_height = nil
    @top = nil
  end 


end
