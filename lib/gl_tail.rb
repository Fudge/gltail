# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the General Public License v2 (see LICENSE)
#

begin
  require 'rubygems'
  require 'bundler/setup'
rescue LoadError
  puts "Rubygems and/or bundler missing."
end

require 'opengl'
require 'gl'
require 'glut'

require 'net/ssh'
require 'net/ssh/gateway'

require 'file/tail'

$PHYSICS = true

require 'chipmunk'

# load our libraries
require 'gl_tail/engine'
require 'gl_tail/config/configurable'
require 'gl_tail/config'
require 'gl_tail/config/yaml_parser'

# sources represent event sources defaults to ssh tail
# future options: JMS queue, spread.org, local tail, etc
require 'gl_tail/sources/base'
require 'gl_tail/sources/ssh'
require 'gl_tail/sources/local'

%w(version engine activity block item element parser resolver blob_store font_store).each {|f| require "gl_tail/#{f}" }

Dir.glob( "#{File.dirname(__FILE__)}/gl_tail/parsers/*.rb" ).each {|f| require f }



