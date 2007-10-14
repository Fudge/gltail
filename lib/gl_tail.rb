# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the General Public License v2 (see LICENSE)
#

begin
  require 'rubygems'
rescue LoadError
  puts "Rubygems missing. Please install."
  puts "Ubuntu:\n  sudo apt-get install rubygems"
end

gem_version = Gem::RubyGemsVersion.split('.')

if gem_version[1].to_i < 9 || (gem_version[1].to_i >= 9 && gem_version[2].to_i < 2)
  puts "rubygems too old to build ruby-opengl. Please update."
  puts "Ubuntu:"
  puts "  sudo gem update --system"
  exit
end

begin
  gem 'ruby-opengl', '>= 0.40.1'
  require 'gl'
  require 'glut'
rescue LoadError
  puts "Missing or outdated gem: ruby-opengl (>=0.40.1)"
  puts "Ubuntu:"
  puts "  sudo apt-get install rake ruby1.8-dev libgl1-mesa-dev libglu1-mesa-dev libglut3-dev"
  puts "  sudo gem install -y ruby-opengl -r"
  exit
end

begin
  gem 'net-ssh'
  require 'net/ssh'
rescue LoadError
  puts "Missing gem net-ssh."
  puts "Ubuntu:"
  puts "  sudo gem install -y net-ssh -r"
  exit
end


# load our libraries
%w( activity block item element server parser resolver ).each {|f| require "lib/#{f}" }

Dir.glob( "lib/parsers/*.rb" ).each {|f| require f }

include Gl
include Glut

$BLOBS = { }
$FPS = 50.0
$ASPECT = 0.6

$TOP = 0.9
$LINE_SIZE = 0.03
$STATS = []

$BITMAP_MODE = 0

class GlTail

  def draw
    glClear(GL_COLOR_BUFFER_BIT);
#    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glPushMatrix()

    positions = Hash.new

    $STATS = [0,0]

    glPushMatrix()

    char_size = 1 * 8.0 / ($WINDOW_WIDTH / 2.0)

    left_left = $LEFT_COL + char_size * ($COLUMN_SIZE_LEFT + 1)
    left_right = $LEFT_COL + char_size * ($COLUMN_SIZE_LEFT + 8)

    right_left = $RIGHT_COL - char_size * ($COLUMN_SIZE_RIGHT + 1)
    right_right = $RIGHT_COL - char_size * ($COLUMN_SIZE_RIGHT + 8)

    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( [0.1, 0.1, 0.1, 1.0]  ) )
    glBegin(GL_QUADS)
      glVertex3f(left_left, 1.0, 0.0)
      glVertex3f(left_right, 1.0, 0.0)
      glVertex3f(left_right, -1.0, 0.0)
      glVertex3f(left_left, -1.0, 0.0)

      glVertex3f(right_left, 1.0, 0.0)
      glVertex3f(right_right, 1.0, 0.0)
      glVertex3f(right_right, -1.0, 0.0)
      glVertex3f(right_left, -1.0, 0.0)
    glEnd()
    glPopMatrix()

    @blocks.values.sort { |k,v| k.order <=> v.order}.each do |block|
      positions[block.position] = block.render( positions[block.position] || 0 )
    end

    glPopMatrix()
    glutSwapBuffers()

    @frames = 0 if not defined? @frames
    @t0 = 0 if not defined? @t0

    @frames += 1
    t = glutGet(GLUT_ELAPSED_TIME)
    if t - @t0 >= 5000
      seconds = (t - @t0) / 1000.0
      $FPS = @frames / seconds
      printf("%d frames in %6.3f seconds = %6.3f FPS\n",
             @frames, seconds, $FPS)
      @t0, @frames = t, 0
      puts "Elements[#{$STATS[0]}], Activities[#{$STATS[1]}]"
    end
  end

  def idle
    glutPostRedisplay()
    do_process
  end

  # Change view angle, exit upon ESC
  def key(k, x, y)
    case k
    when 27 # Escape
      exit
    end
    glutPostRedisplay()
  end

  # Change view angle
  def special(k, x, y)
    glutPostRedisplay()
  end

  # New window size or exposure
  def reshape(width, height)
    $ASPECT = height.to_f / width.to_f

    $WINDOW_WIDTH, $WINDOW_HEIGHT = width, height

    puts "Reshape: #{width}x#{height} = #{$ASPECT}"

    glViewport(0, 0, width, height)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

#    glFrustum(-2.0, 2.0, -$ASPECT*2, $ASPECT*2, 5.0, 60.0)
    glOrtho(-1.0, 1.0, -$ASPECT, $ASPECT, -1.0, 1.0)

    $TOP = $ASPECT - ($ASPECT/20)
    $LINE_SIZE = 0.025 * (1122/height.to_f) * $ASPECT


    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslate(0.0, 0.0, 0.0)
  end

  def init
    glLightfv(GL_LIGHT0, GL_POSITION, [5.0, 5.0, 10.0, 0.0])
    glDisable(GL_CULL_FACE)
    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)

    glDisable(GL_DEPTH_TEST)
    glDisable(GL_NORMALIZE)

    @channels = Array.new
    @sessions = Array.new
    @servers = Hash.new
    @blocks = Hash.new
    @mode = 0

    $BLOCKS.each do |b|
      @blocks[b[:name]] = Block.new b
    end

    $SERVERS.each do |s|
      puts "Connecting to #{s[:host]}..."
      session_options = { }
      session_options[:port] = s[:port] if s[:port]
      session_options[:keys] = s[:keys] if s[:keys]
      session_options[:verbose] = :debug if $DBG > 1
      begin
      if s[:password]
        session_options[:auth_methods] = [ "password","keyboard-interactive" ]
        session = Net::SSH.start(s[:host], s[:user], s[:password], session_options)
      else
        session = Net::SSH.start(s[:host], s[:user], session_options)
      end
      rescue SocketError => e
        puts "!!! Could not connect to #{s[:host]}. Check to make sure that this is the correct url."
        puts $! if $DBG > 0
        exit
      rescue Net::SSH::AuthenticationFailed => e
        puts "!!! Could not authenticate on #{s[:host]}. Make sure you have set the username and password correctly. Or if you are using SSH keys make sure you have not set a password."
        puts $! if $DBG > 0
        exit
      end
      do_tail session, s[:name], s[:color], s[:files].join(" "), s[:command]
      session.connection.process
      @sessions.push session
      @servers[s[:name]] ||= Server.new(:name => s[:name] || s[:host], :host => s[:host], :color => s[:color], :parser => s[:parser], :blocks => @blocks )
    end

    @since = glutGet(GLUT_ELAPSED_TIME)
  end

  def timer(value)
    glutPostRedisplay()
    glutTimerFunc(33, method(:timer).to_proc, 0)
    do_process
  end

  def visible(vis)
#    glutTimerFunc(33, method(:timer).to_proc, 0)
    glutIdleFunc((vis == GLUT_VISIBLE ? method(:idle).to_proc : nil))
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

  def initialize
    glutInit()
    glutInitDisplayMode(GLUT_RGB | GLUT_DOUBLE)
    glutInitDisplayMode(GLUT_RGB | GLUT_DEPTH | GLUT_DOUBLE)

    glutInitWindowPosition(0, 0)
    glutInitWindowSize($WINDOW_WIDTH, $WINDOW_HEIGHT)
    glutCreateWindow('glTail')
    init()

    glutDisplayFunc(method(:draw).to_proc)
    glutReshapeFunc(method(:reshape).to_proc)
    glutKeyboardFunc(method(:key).to_proc)
    glutSpecialFunc(method(:special).to_proc)
    glutVisibilityFunc(method(:visible).to_proc)
    glutMouseFunc(method(:mouse).to_proc)
    glutMotionFunc(method(:motion).to_proc)
  end

  def start
    glutMainLoop()
  end

  def parse_line( ch, data )
    ch[:buffer].gsub(/\r\n/,"\n").gsub(/\n/, "\n\n").each("") do |line|

      unless line.include? "\n\n"
        ch[:buffer] = "#{line}"
        next
      end


      line.gsub!(/\n\n/, "\n")
      line.gsub!(/\n\n/, "\n")

      puts "#{ch[:host]}[#{ch[:name]}]: #{line}" if $DBG > 0

      server = @servers.values.find { |v| (v.host == ch[:host]) && (v.name == ch[:name]) }
      server.parser.parse(line)
    end
    ch[:buffer] = "" if ch[:buffer].include? "\n"
  end

  def do_tail( session, name, color, file, command )
    session.open_channel do |channel|
      puts "Channel opened on #{session.host}...\n"
      channel[:host] = session.host
      channel[:name] = name
      channel[:color] = color
      channel[:buffer] = ""
      channel.request_pty :want_reply => true

      channel.on_data do |ch, data|
        ch[:buffer] << data
        parse_line(ch, data)
      end

      channel.on_success do |ch|
        channel.exec "#{command} #{file}  "
      end

      channel.on_failure do |ch|
        ch.close
      end

      channel.on_extended_data do |ch, data|
        puts "STDERR: #{data}\n"
      end

      channel.on_close do |ch|
        ch[:closed] = true
      end

      puts "Pushing #{channel[:host]}\n"
      @channels.push(channel)
    end
  end

  def do_process
    active = 0
    @channels.each do |ch|
      active += 1
      ch.connection.process(true)
    end

    break if active == 0

    if glutGet(GLUT_ELAPSED_TIME) - @since >= 1000
      @since = glutGet(GLUT_ELAPSED_TIME)
      @channels.each { |ch| ch.connection.ping! }

      @blocks.each_value do |b|
        b.update
      end
    end
    self
  end

end

