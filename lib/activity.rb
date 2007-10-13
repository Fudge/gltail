# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Activity
  attr_accessor :x, :y, :z, :type, :wx, :wy, :wz

  def initialize(message, x,y,z, color, size, type=0)
    @message = message
    @x, @y, @z = x, y, z
#    @xi, @yi, @zi = 0.020 + ( (rand(100)/100.0 - 0.5) * 0.01 ), (rand(100)/100.0 - 0.6) * 0.0025, 0
    @xi, @yi, @zi = 0.015 , 0.0025, 0

    if @x >= 0.0
      @xi = -@xi
    end

    @xi = (rand(100)/100.0 * 0.02) - 0.01 if type == 2

    @color = color
    @size  = size
    @type  = type
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

  def render

    if @type == 5
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

    else
      @x += @xi
      @y += @yi

      if @y - @size/2 < -$TOP
        @y = -$TOP + @size/2
        @yi = -@yi * 0.7
        @x = 30.0 #if @type == 2
      end

     @yi = @yi - 0.0005
#      @yi = @yi * 1.01

    end

    if @type == 0 || @type == 5
      glPushMatrix()
      glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @color)
      glTranslate(@x, @y, @z)


      if( $BLOBS[@size].nil? )
        list = glGenLists(1)
        glNewList(list, GL_COMPILE)
        glutSolidSphere(@size, 10, 2)
        glEndList()
        $BLOBS[@size] = list
      end
      glCallList($BLOBS[@size])
      glPopMatrix()
    elsif @type == 1
      glPushMatrix()
      glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @color)
      glTranslate(@x, @y, @z)

      if( $BLOBS[@size].nil? )
        list = glGenLists(1)
        glNewList(list, GL_COMPILE)
        glutSolidSphere(@size, 10, 2)
        glEndList()
        $BLOBS[@size] = list
      end
      glCallList($BLOBS[@size])
      glPopMatrix()
    elsif @type == 2
      glPushMatrix()
      glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, @color.map { |c| c*3.0} )
      glTranslate(@x, @y, @z)
      glRasterPos(0.0, 0.0)

      if( $BLOBS[@message].nil? )
        list = glGenLists(1)
        glNewList(list, GL_COMPILE)
        print_text @message
        glEndList()
        $BLOBS[@message] = list
      end
      glCallList($BLOBS[@message])
      glPopMatrix()
    end
  end
end
