# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the General Public License v2 (see LICENSE)
#

module GlTail
  VERSION = '0.1.7'
end

begin
  require 'rubygems'
rescue LoadError
  puts "Rubygems missing. Please install."
  puts "Ubuntu:\n  sudo apt-get install rubygems"
end

gem_version = Gem::RubyGemsVersion.split('.')

if gem_version[0].to_i == 0 && gem_version[1].to_i < 9 || (gem_version[0].to_i == 0 && gem_version[1].to_i >= 9 && gem_version[2].to_i < 2)
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
  puts "\nFor more information: http://ruby-opengl.rubyforge.org/build_install.html"
  exit
end

begin
  gem 'net-ssh', '< 1.2'
  require 'net/ssh'
rescue LoadError
  puts "Missing gem net-ssh."
  puts "Ubuntu:"
  puts "  sudo gem install -y net-ssh -v 1.1.4 -r"
  exit
end

begin
  require 'file/tail'
rescue LoadError
  puts "Missing gem file-tail."
  puts "Ubuntu:"
  puts "  sudo gem install -y file-tail -r"
  exit
end

begin
  require 'chipmunk'
rescue LoadError
  puts "Missing Chipmunk C extension."
  puts "Ubuntu:"
  puts "  cd vendor/Chipmunk-4.1.0/ruby"
  puts "  ruby extconf.rb"
  puts "  sudo make install"
  puts "  cd ../../../"
  exit
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



