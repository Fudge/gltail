require 'mkmf'

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

if ARGV.member?('--help') || ARGV.member?('-?')
  puts "ruby extconf.rb:"
  puts "Options for the Ruby bindings to Chipmunk: "
#  puts "--disable-vendor    Disables vendoring Chipmunk."
#  puts "--enable-vendor     Enables vendoring Chipmunk."
  puts "--enable-macosx     Enables compiling for OS-X."
  puts "--enable-64         Enables compiling to 64 bits targets."
  puts
  exit
end

p "pwd", Dir.pwd

dir_config('chipmunk')

# VENDORED_CHIPMUNK     = 'chipmunk-5.3.4'
# VENDORED_SRC_DIR      =  File.join($srcdir, 'vendor', VENDORED_CHIPMUNK, 'src')
# VENDORED_SRC_DIR2     =  File.join($srcdir, 'vendor', VENDORED_CHIPMUNK, 'src',
#                                   'constraints')
# VENDORED_INCLUDE_DIR  =  File.join($srcdir, 'vendor', VENDORED_CHIPMUNK, 'include'
#                                'chipmunk')

MINGW = '/usr/i586-mingw32msvc'
CHIPMUNK_HEADER   = 'chipmunk.h'
CHIPMUNK_NAME     = 'chipmunk'
CHIPMUNK_FUNCTION = 'cpMomentForPoly'
CHIPMUNK_INCLUDE  = [ '/usr/include',
                      File.join(MINGW, 'include'),
                      File.join(MINGW, 'include', 'chipmunk'),
                     '/usr/local/include',
                     '/usr/include/chipmunk',
                     '/usr/local/include/chipmunk'
                    ]
CHIPMUNK_LIBDIR   = ['/usr/lib', File.join(MINGW, 'lib'), '/usr/local/lib']

# This is a bit of a trick to cleanly vendor the chipmunk C library.
# sources           = Dir.glob(File.join($srcdir, 'rb_*.c')).to_a
# normally, we need the rb_xxx files...

have_header('chipmunk.h')

if enable_config("macosx", false)
    $CFLAGS += ' -arch ppc -arch i386 -arch x86_64'
    $LDFLAGS += ' -arch x86_64 -arch i386 -arch ppc'
end

if enable_config("64", false)
  $CFLAGS += ' -m64'
end

$CFLAGS += ' -std=gnu99 -ffast-math -DNDEBUG '
create_makefile('chipmunk')

