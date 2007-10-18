
include Gl
include Glut


module GlTail
  class Engine
    def render_string(string)
      FontStore.render_string(self, string)
    end
    
    def screen
      @config.screen
    end
  
    def char_size
      @char_size ||= (8.0 / (@config.screen.window_width / 2.0))
    end
    
    def line_size
      @config.screen.line_size
    end
    
    def highlight_color
      @config.screen.highlight_color
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
      glPopMatrix()

      # TODO: do we really need to sort every block on every draw?!
      # Nope. But it was a hash, so keeping order was a bit hard.
      @config.blocks.sort { |k,v| k.order <=> v.order}.each do |block|
        # glPushMatrix + glTranslate3f to render each element relativ to its containing block instead of the screen?
        positions[block.is_right] = block.render(self, positions[block.is_right] || 0 )
      end

      glPopMatrix()

      @frames += 1
      t = glutGet(GLUT_ELAPSED_TIME)
      if t - @t0 >= 5000
        seconds = (t - @t0) / 1000.0
        $FPS = @frames / seconds
        printf("%d frames in %6.3f seconds = %6.3f FPS\n",
        @frames, seconds, $FPS)
        @t0, @frames = t, 0
        puts "Elements[#{stats[0]}], Activities[#{stats[1]}], Blobs[#{BlobStore.used}/#{BlobStore.size}]"
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
      glutTimerFunc(15, method(:timer).to_proc, 0)
      #    t = glutGet(GLUT_ELAPSED_TIME)
      glutPostRedisplay()
      glutSwapBuffers()
      do_process
      #    t = glutGet(GLUT_ELAPSED_TIME) - t
      #    t = 14 if t > 14
    end

    # Change view angle, exit upon ESC
    def key(k, x, y)
      case k
      when 27 # Escape
        exit
      when 32 # Space
        @config.screen.bounce ||= false
        @config.screen.bounce = !@config.screen.bounce
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
      when 98
        @config.screen.mode = 1 - @config.screen.mode.to_i
        BlobStore.empty
      end
      puts "Keypress: #{k}"
      glutPostRedisplay()
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

      puts "Reshape: #{width}x#{height} = #{@config.screen.aspect}/#{@config.screen.line_size}"

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity()
      glTranslate(0.0, 0.0, 0.0)

      BlobStore.empty # Flush cached objects to recreate with correct size
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
    end

    def start
      glutInit()
      glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE)

      glutInitWindowPosition(0, 0)
      glutInitWindowSize(@config.screen.window_width, @config.screen.window_height)
      glutCreateWindow('glTail')

      glutDisplayFunc(method(:draw).to_proc)
      glutReshapeFunc(method(:reshape).to_proc)
      glutKeyboardFunc(method(:key).to_proc)
      glutSpecialFunc(method(:special).to_proc)
      glutVisibilityFunc(method(:visible).to_proc)
      glutMouseFunc(method(:mouse).to_proc)
      glutMotionFunc(method(:motion).to_proc)

      glutIdleFunc(method(:idle).to_proc)
      #    glutTimerFunc(33, method(:timer).to_proc, 0)      
      
      glLightfv(GL_LIGHT0, GL_POSITION, [5.0, 5.0, 0.0, 0.0])
      glLightfv(GL_LIGHT0, GL_AMBIENT, [0,0,0,1])
      glDisable(GL_CULL_FACE)
      glEnable(GL_LIGHTING)
      glEnable(GL_LIGHT0)
      glEnable(GL_TEXTURE_2D)
      #    glShadeModel(GL_FLAT)
      glDisable(GL_DEPTH_TEST)
      glDisable(GL_NORMALIZE)
      #    glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST)
      glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_FASTEST )

      glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE)
      glEnable(GL_COLOR_MATERIAL)
      glEnable(GL_NORMALIZE)
      FontStore.generate_font

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
          BlobStore.prune
        end
      end
      
      self
    end
  end
end
