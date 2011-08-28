
include Gl
include Glut

module GlTail
  class Engine

    INF = 1.0/0

    attr_accessor :space

    def render_string(text, cache=true, pos=0)
      FontStore.render_string(self, text, cache, pos)
    end

    def screen
      @screen ||= @config.screen
    end

    def char_size
      @char_size ||= (8.0 / (@config.screen.window_width / 2.0))
    end

    def line_size
      self.screen.line_size
    end

    def highlight_color
      self.screen.highlight_color
    end

    def reset_stats
      @stats = [0, 0]
    end

    def stats
      @stats
    end

    def draw
      @render_time ||= 0
      @t = Time.new

      @space.step(1.0/60.0) if $PHYSICS

      glClear(GL_COLOR_BUFFER_BIT);
      #    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

      glPushMatrix()

      positions = Hash.new

      reset_stats

      glPushMatrix()

      glColor([0.15, 0.15, 0.15, 1.0])
      glBegin(GL_QUADS)
      glNormal3f(1.0, 1.0, 0.0)

      glVertex3f(@left_left, @config.screen.aspect, 0.0)
      glVertex3f(@left_right, @config.screen.aspect, 0.0)
      glVertex3f(@left_right, -@config.screen.aspect, 0.0)
      glVertex3f(@left_left, -@config.screen.aspect, 0.0)
      
      glVertex3f(@right_left, @config.screen.aspect, 0.0)
      glVertex3f(@right_right, @config.screen.aspect, 0.0)
      glVertex3f(@right_right, -@config.screen.aspect, 0.0)
      glVertex3f(@right_left, -@config.screen.aspect, 0.0)

      glEnd()

      if @config.screen.bounce
        left  = @left_right
        right = @right_right
        bottom = (-@config.screen.top)
        middle = (-@config.screen.top) / 2.0
        center = 0.1 

        glColor([0.15, 0.15, 0.15, 1.0])
        glEnable(GL_LINE_SMOOTH)
        glBegin(GL_LINES)
        glVertex3f(left, middle, 0.0)
        glVertex3f(-center, bottom, 0.0)

        glVertex3f(left, middle, 0.0)
        glVertex3f(-center, bottom, 0.0)

        glVertex3f(right, middle, 0.0)
        glVertex3f(center, bottom, 0.0)
        glEnd()
        glDisable(GL_LINE_SMOOTH)
      end 

      glPopMatrix()

      @config.blocks.each do |block|
        # glPushMatrix + glTranslate3f to render each element relativ to its containing block instead of the screen?
        positions[block.is_right] = block.render(self, positions[block.is_right] || 0 )
      end

      glPopMatrix()

      @frames += 1
      t = glutGet(GLUT_ELAPSED_TIME)
      if t - @t0 >= 10000
        seconds = (t - @t0) / 1000.0
        $FPS = @frames / seconds
        printf("%d frames in %6.3f seconds = %6.3f FPS\n",
        @frames, seconds, $FPS) if $VRB > 0
        @t0, @frames = t, 0
        puts "Elements[#{stats[0]}], Activities[#{stats[1]}], Blobs[#{BlobStore.used}/#{BlobStore.size}]" if $VRB > 0
      end

      @render_time = (Time.new - @t)
    end

    def idle
      @last_run ||= Time.new
      @last_run_time ||= 0
      delta = (Time.new - @last_run) - @last_run_time
      if @config.screen.wanted_fps > 0 && delta < (1000.0/(@config.screen.wanted_fps*1000.0))
        sleep((1000.0/(@config.screen.wanted_fps*1000.0) - delta))
      end
      @last_run = Time.new
      glutPostRedisplay()
      glutSwapBuffers()
      do_process
      @last_run_time = (@last_run_time.to_f * (@config.screen.wanted_fps-1.0) + (Time.new - @last_run).to_f) / @config.screen.wanted_fps.to_f if @config.screen.wanted_fps > 0
    end

    def timer(value)
      glutTimerFunc(14, method(:timer).to_proc, 0)
      #    t = glutGet(GLUT_ELAPSED_TIME)
      glutPostRedisplay()
      glutSwapBuffers()
      do_process
      #    t = glutGet(GLUT_ELAPSED_TIME) - t
      #    t = 14 if t > 14
    end

    # Change view angle, exit upon ESC
    def key(k, x, y)
      case k.ord
      when 27 # Escape
        exit
      when 32 # Space
        @config.screen.bounce ||= false
        @config.screen.bounce = !@config.screen.bounce
        puts "Bounce: #{@config.screen.bounce}"
        reshape(@config.screen.window_width, @config.screen.window_height)
      when 102 #f
        @config.screen.wanted_fps = case @config.screen.wanted_fps
                                    when 0
                                      60
                                    when 60
                                      50
                                    when 50
                                      45
                                    when 45
                                      30
                                    when 30
                                      25
                                    when 25
                                      20
                                    when 20
                                      0
                                    end
        puts "WANTED_FPS[#{@config.screen.wanted_fps}]"
      when 70 #F (shift + f) - toggle fullscreen mode
        @config.screen.fullscreen = !@config.screen.fullscreen
        set_fullscreen @config.screen.fullscreen
      when 98 #v
        @config.screen.mode = 1 - @config.screen.mode.to_i
        BlobStore.empty
      end
      puts "Keypress: #{k.ord}"
      glutPostRedisplay()
    end
    
    # when toggling fullscreen, we need to remember the original coordinates
    # so that when we restore the windowed mode we know how big it should be.
    def set_fullscreen fullscreen
      if fullscreen
        @last_window_width = @config.screen.window_width
        @last_window_height = @config.screen.window_height
        glutFullScreen()
      else
        glutReshapeWindow(@last_window_width, @last_window_height)
      end
      
    end

    # Change view angle
    def special(k, x, y)
      glutPostRedisplay()
    end

    # New window size or exposure
    def reshape(width, height)
      @config.reshape(width, height)

      # reset char size
      @char_size = nil

      @left_left = @config.screen.left.alignment + char_size * (@config.screen.left.size + 1)
      @left_right = @config.screen.left.alignment + char_size * (@config.screen.left.size + 8)

      @right_left = @config.screen.right.alignment - char_size * (@config.screen.right.size + 1)
      @right_right = @config.screen.right.alignment - char_size * (@config.screen.right.size + 8)

      glViewport(0, 0, width, height)
      glMatrixMode(GL_PROJECTION)
      glLoadIdentity()

      #    glFrustum(-1.0, 1.0, -@config.screen.aspect, @config.screen.aspect, 5.0, 60.0)
      glOrtho(-1.0, 1.0, -@config.screen.aspect, @config.screen.aspect, -1.0, 1.0)

      @config.screen.line_size = @config.screen.aspect * 2 / (@config.screen.window_height/13.0)
      @config.screen.top = @config.screen.aspect - @config.screen.line_size

      puts "Reshape: #{width}x#{height} = #{@config.screen.aspect}/#{@config.screen.line_size}" if $VRB > 0

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity()
      glTranslate(0.0, 0.0, 0.0)

      BlobStore.empty # Flush cached objects to recreate with correct size

      if !defined?(@static_body) && $PHYSICS
        puts "Adding static shapes.."
        @static_body = CP::Body.new(Float::MAX, Float::MAX)
      end 

      if @config.screen.bounce && $PHYSICS
        if @static_shapes && @static_shapes.size > 0 
          0.upto(3) do |i|
            @space.remove_static_shape(@static_shapes[i])
          end 
          @static_shapes.clear
        else 
          @static_shapes = []
        end 

        left  = @left_right * @config.screen.window_width * @config.screen.aspect
        right = @right_right * @config.screen.window_width * @config.screen.aspect
        bottom = (-@config.screen.top) * @config.screen.window_height
        middle = (-@config.screen.top) * @config.screen.window_height / 2.0
        center = 0.1 * @config.screen.window_width * @config.screen.aspect

        shape = CP::Shape::Segment.new(@static_body, CP::Vec2.new(left,middle), CP::Vec2.new(-center,bottom), 3)
        shape.e = 0.9
        shape.u = 1
        @space.add_static_shape(shape)
        @static_shapes[0] = shape
      
        shape = CP::Shape::Segment.new(@static_body, CP::Vec2.new(right,middle), CP::Vec2.new(center,bottom), 3)
        shape.e = 0.9
        shape.u = 1
        @space.add_static_shape(shape)
        @static_shapes[1] = shape
        
        shape = CP::Shape::Segment.new(@static_body, CP::Vec2.new(right,middle), CP::Vec2.new(right,-bottom), 3)
        shape.e = 0.9
        shape.u = 1
        @space.add_static_shape(shape)
        @static_shapes[2] = shape
        
        shape = CP::Shape::Segment.new(@static_body, CP::Vec2.new(left,middle), CP::Vec2.new(left,-bottom), 3)
        shape.e = 0.9
        shape.u = 1
        @space.add_static_shape(shape)
        @static_shapes[3] = shape
      elsif @static_shapes && @static_shapes.size > 0 
        0.upto(3) do |i|
          @space.remove_static_shape(@static_shapes[i])
        end 
        @static_shapes.clear
      end 

      @config.blocks.each do |block|
        block.reshape
      end

    end

    def visible(vis)
      #    glutIdleFunc((vis == GLUT_VISIBLE ? method(:idle).to_proc : nil))
    end

    def mouse(button, state, x, y)
      @mouse = state
      @x0, @y0 = x, y
    end

    def motion(x, y)
      if @mouse == GLUT_DOWN then
      end
      @x0, @y0 = x, y
    end

    def initialize(config)
      @config = config

      @frames = 0
      @t0 = 0
      @left_left = @left_right = @right_left = @right_right = 0.0 # TODO: Why is draw called before these are set by reshape?

      if $PHYSICS
        @space = CP::Space.new
        @space.damping = 0.89
        @space.gravity = CP::Vec2.new(0, -85)
        @space.iterations = 2
        @space.elastic_iterations = 0
      end 
    end

    def start
      glutInit()
      glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE)

      glutInitWindowPosition(0, 0)
      glutInitWindowSize(@config.screen.window_width, @config.screen.window_height)
      glutCreateWindow('glTail')
      
      # check if we should start in fullscreen
      if @config.screen.fullscreen
        set_fullscreen true
      end

      glutDisplayFunc(method(:draw).to_proc)
      glutReshapeFunc(method(:reshape).to_proc)
      glutKeyboardFunc(method(:key).to_proc)
      glutSpecialFunc(method(:special).to_proc)
      glutVisibilityFunc(method(:visible).to_proc)
      glutMouseFunc(method(:mouse).to_proc)
      glutMotionFunc(method(:motion).to_proc)

#     glutIdleFunc(method(:idle).to_proc)
      glutTimerFunc(14, method(:timer).to_proc, 0)

#      glLightfv(GL_LIGHT0, GL_POSITION, [5.0, 5.0, 0.0, 0.0])

#      glLightfv(GL_LIGHT0, GL_AMBIENT, [0,0,0,1])

#      glLightModel(GL_LIGHT_MODEL_AMBIENT, [0.1,0.1,0.1,1]);

#      glLightModel(GL_LIGHT_MODEL_LOCAL_VIEWER, 1);
#      glLightModel(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR);

      glDisable(GL_CULL_FACE)
#      glEnable(GL_LIGHTING)
#      glEnable(GL_LIGHT0)
      glEnable(GL_TEXTURE_2D)
#      glShadeModel(GL_FLAT)
      glDisable(GL_DEPTH_TEST)
#      glDisable(GL_NORMALIZE)
#      glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST)
      glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST )

      glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
      glEnable(GL_COLOR_MATERIAL)
      glEnable(GL_NORMALIZE)
 

      FontStore.generate_font

      glBlendFunc(GL_ONE, GL_ONE) # Make text transparent

      @since = glutGet(GLUT_ELAPSED_TIME)

      @config.init

      glutMainLoop()
    end

    def do_process
      active = @config.do_process

      if active >= 0

        if glutGet(GLUT_ELAPSED_TIME) - @since >= 1000
          @since = glutGet(GLUT_ELAPSED_TIME)
          @config.update
          BlobStore.prune(@since)
        end
      end

      self
    end
  end
end
