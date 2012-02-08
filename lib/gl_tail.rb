# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the General Public License v2 (see LICENSE)
#

module GlTail
  VERSION = '0.1.9'
end

begin
  require 'rubygems'
rescue LoadError
  puts "Rubygems missing. Please install."
  puts "Ubuntu:\n  sudo apt-get install rubygems"
end

gem_version = Gem::RubyGemsVersion.split('.')

if gem_version[0].to_i == 0 && gem_version[1].to_i < 9 || (gem_version[0].to_i == 0 && gem_version[1].to_i >= 9 && gem_version[2].to_i < 2)
  puts "rubygems too old to build opengl. Please update."
  puts "Ubuntu:"
  puts "  sudo gem update --system"
  exit
end

begin
  gem 'opengl', '~> 0.7.0.pre1'
  require 'gl'
  require 'glut'
rescue LoadError
  puts "Missing or outdated gem: opengl (~> 0.7.0.pre1)"
  puts "Ubuntu:"
  puts "  sudo apt-get install rake ruby1.8-dev libgl1-mesa-dev libglu1-mesa-dev libglut3-dev"
  puts "  sudo gem install -y opengl --pre -r"
  puts "\nFor more information: http://rubygems.org/gems/opengl"
  exit
end

begin
  gem 'net-ssh'
  require 'net/ssh'
rescue LoadError
  puts "Missing gem net-ssh."
  puts "Ubuntu:"
  puts "  sudo gem install -y net-ssh net-ssh-gateway -r"
  exit
end

begin
  gem 'net-ssh-gateway'
  require 'net/ssh/gateway'
rescue LoadError
  puts "Missing gem net-ssh-gateway."
  puts "Ubuntu:"
  puts "  sudo gem install -y net-ssh-gateway -r"
end

begin
  require 'file/tail'
rescue LoadError
  puts "Missing gem file-tail."
  puts "Ubuntu:"
  puts "  sudo gem install -y file-tail -r"
  exit
end

$PHYSICS = true

begin
  require 'chipmunk'
rescue LoadError
  puts "Missing Chipmunk C extension. Disabling physics..."
  puts "Ubuntu:"
  puts "  sudo gem install -y chipmunk -r"

  $PHYSICS = false
end

$:.unshift(File.dirname(__FILE__)) # this should be obsolete once its a gem

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

%w( engine activity block item element parser resolver blob_store font_store).each {|f| require "gl_tail/#{f}" }

Dir.glob( "#{File.dirname(__FILE__)}/gl_tail/parsers/*.rb" ).each {|f| require f }



