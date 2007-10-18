# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Activity
  attr_accessor :x, :y, :z, :wx, :wy, :wz, :xi, :yi, :zi
  attr_accessor :message, :color, :size, :type

  def initialize(message, x, y, z, color, size, type = 0)
    @message = message
    @x, @y, @z = x, y, z
    @xi, @yi, @zi = 0.012 + (rand(100)/100.0 ) * 0.0012 , 0.002 + (rand(1000)/1000.0 ) * 0.002, 0
#    @xi, @yi, @zi = 0.015 , 0.0025, 0

    if @x >= 0.0
      @xi = -@xi
    end

    @xi = (rand(100)/100.0 * 0.02) - 0.01 if type == 2

    @color = color
    @size  = size
    @type  = type

    @rx, @ry, @rz = rand(360), rand(360), 0
  end

  def render(engine)
    if @type != 5
      if engine.screen.wanted_fps == 0
        @x += @xi/2
        @y += @yi/2
        @yi = @yi - 0.0005/2
      else
        @fps_mod ||= (60.0 / engine.screen.wanted_fps)
        @x += (@xi/2) * @fps_mod
        @y += (@yi/2) * @fps_mod
        @yi = @yi - (0.0005/2) * @fps_mod
      end

#      @yi = @yi * 1.01
#      @xi = @xi * 0.9995

      if @y - @size/2 < -engine.screen.top
        @y = -engine.screen.top + @size/2
        @yi = -@yi * 0.7
        @x = 30.0 if(@type == 2 || (engine.screen.bounce.nil? || engine.screen.bounce == false ) )
      end
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

    glPushMatrix()
    glColor(@color)

    if @type == 0 || @type == 5
      glTranslate(@x, @y, @z)
      if engine.screen.mode == 1
        glRotatef(@rx, 1.0, 0.0, 0.0)
        glRotatef(@ry, 0.0, 1.0, 0.0)
        @rx += 2
        @ry += 1
        unless BlobStore.has(@size)
          list = glGenLists(1)
          glNewList(list, GL_COMPILE)

          glBegin(GL_QUADS)
          glVertex3f(-@size,  @size, 0)
          glVertex3f( @size,  @size, 0)
          glVertex3f( @size, -@size, 0)
          glVertex3f(-@size, -@size, 0)
          glEnd

          glEndList()
          BlobStore.put(@size,list)
        end
      else
        unless BlobStore.has(@size)

          list = glGenLists(1)
          glNewList(list, GL_COMPILE)
          
          tmp = 10 + 10 * ((@size-engine.screen.min_blob_size)/engine.screen.max_blob_size)
          if not tmp
            puts "THIS KEEPS CRASHING FOR ME WITH tmp == NaN -- cant figure out why"
            tmp = 2
          end
          
          glutSolidSphere(@size, tmp, 2)
          glEndList()
          BlobStore.put(@size,list)
        end
      end
      glCallList(BlobStore.get(@size))
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

      engine.render_string(@message)
    end

    glPopMatrix()
  end
end
