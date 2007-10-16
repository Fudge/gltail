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
%w( activity block item element server parser resolver blob_store font_store).each {|f| require "lib/#{f}" }

Dir.glob( "lib/parsers/*.rb" ).each {|f| require f }

include Gl
include Glut

$CONFIG.wanted_fps = 0
$CONFIG.aspect = 0.6

$CONFIG.top = 0.9
$CONFIG.line_size = 0.03
$CONFIG.stats = []

$CONFIG.bitmap_mode = 0

class GlTail

  def draw
    @render_time ||= 0
    @t = Time.new

    glClear(GL_COLOR_BUFFER_BIT);
#    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glPushMatrix()

    positions = Hash.new

    $CONFIG.stats = [0,0]

    glPushMatrix()

    char_size = 1 * 8.0 / ($CONFIG.window_width / 2.0)

    left_left = $CONFIG.left[:alignment] + char_size * ($CONFIG.left[:size] + 1)
    left_right = $CONFIG.left[:alignment] + char_size * ($CONFIG.left[:size] + 8)

    right_left = $CONFIG.right[:alignment] - char_size * ($CONFIG.right[:size] + 1)
    right_right = $CONFIG.right[:alignment] - char_size * ($CONFIG.right[:size] + 8)

    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( [0.2, 0.2, 0.2, 10.0]  ) )
    glBegin(GL_QUADS)
      glVertex3f(left_left, $CONFIG.aspect, 0.0)
      glVertex3f(left_right, $CONFIG.aspect, 0.0)
      glVertex3f(left_right, -$CONFIG.aspect, 0.0)
      glVertex3f(left_left, -$CONFIG.aspect, 0.0)

      glVertex3f(right_left, $CONFIG.aspect, 0.0)
      glVertex3f(right_right, $CONFIG.aspect, 0.0)
      glVertex3f(right_right, -$CONFIG.aspect, 0.0)
      glVertex3f(right_left, -$CONFIG.aspect, 0.0)
    glEnd()
    glPopMatrix()

    @blocks.values.sort { |k,v| k.order <=> v.order}.each do |block|
      positions[block.position] = block.render( positions[block.position] || 0 )
    end

    glPopMatrix()

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
      puts "Elements[#{$CONFIG.stats[0]}], Activities[#{$CONFIG.stats[1]}], Blobs[#{BlobStore.used}/#{BlobStore.size}]"
    end
    @render_time = (Time.new - @t)
  end

  def idle
    @last_run ||= Time.new
    @last_run_time ||= 0
    delta = (Time.new - @last_run) - @last_run_time
    if $CONFIG.wanted_fps > 0 && delta < (1000.0/($CONFIG.wanted_fps*1000.0))
      sleep((1000.0/($CONFIG.wanted_fps*1000.0) - delta))
    end
    @last_run = Time.new
    glutPostRedisplay()
    glutSwapBuffers()
    do_process
    @last_run_time = (@last_run_time.to_f * ($CONFIG.wanted_fps-1.0) + (Time.new - @last_run).to_f) / $CONFIG.wanted_fps.to_f if $CONFIG.wanted_fps > 0
  end

  def timer(value)
    t = glutGet(GLUT_ELAPSED_TIME)
    glutPostRedisplay()
    do_process
    t = glutGet(GLUT_ELAPSED_TIME) - t
    t = 29 if t > 29
    glutTimerFunc(30 - t, method(:timer).to_proc, 0)
  end

  # Change view angle, exit upon ESC
  def key(k, x, y)
    case k
    when 27 # Escape
      exit
    when 102 #f
      $CONFIG.wanted_fps = case $CONFIG.wanted_fps
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
      puts "WANTED_FPS[#{$CONFIG.wanted_fps}]"
    when 98
      $MODE = 1 - $MODE.to_i
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
    $CONFIG.aspect = height.to_f / width.to_f

    $CONFIG.window_width, $CONFIG.window_height = width, height


    glViewport(0, 0, width, height)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

#    glFrustum(-2.0, 2.0, -$CONFIG.aspect*2, $CONFIG.aspect*2, 5.0, 60.0)
    glOrtho(-1.0, 1.0, -$CONFIG.aspect, $CONFIG.aspect, -1.0, 1.0)

    $CONFIG.line_size = $CONFIG.aspect * 2 / ($CONFIG.window_height/13.0)
    $CONFIG.top = $CONFIG.aspect - $CONFIG.line_size

    puts "Reshape: #{width}x#{height} = #{$CONFIG.aspect}/#{$CONFIG.line_size}"

    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslate(0.0, 0.0, 0.0)

    BlobStore.empty # Flush cached objects to recreate with correct size
  end

  def init
    glLightfv(GL_LIGHT0, GL_POSITION, [-5.0, 5.0, 10.0, 0.0])
    glDisable(GL_CULL_FACE)
    glEnable(GL_LIGHTING)
    glEnable(GL_LIGHT0)
    glEnable(GL_TEXTURE_2D)

    glDisable(GL_DEPTH_TEST)
    glDisable(GL_NORMALIZE)
#    glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST)

    FontStore.generate_font

    @channels = Array.new
    @sessions = Array.new
    @servers = Hash.new
    @blocks = Hash.new
    @mode = 0

    $CONFIG.blocks.each do |b|
      @blocks[b[:name]] = Block.new b
    end

    $CONFIG.servers.each do |s|
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

    glutInitWindowPosition(0, 0)
    glutInitWindowSize($CONFIG.window_width, $CONFIG.window_height)
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
    while true
      t = glutGet(GLUT_ELAPSED_TIME)
      glutCheckLoop()
      puts "#{glutGet(GLUT_ELAPSED_TIME) - t} ms"
    end
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
      while ch.connection.reader_ready?
        ch.connection.process(true)
      end
    end

    break if active == 0

    if glutGet(GLUT_ELAPSED_TIME) - @since >= 1000
      @since = glutGet(GLUT_ELAPSED_TIME)
      @channels.each { |ch| ch.connection.ping! }

      @blocks.each_value do |b|
        b.update
      end

      BlobStore.prune
    end
    self
  end

end

