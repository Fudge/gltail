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

%w( engine activity block item element parser resolver blob_store font_store).each {|f| require "gl_tail/#{f}" }

Dir.glob( "#{File.dirname(__FILE__)}/gl_tail/parsers/*.rb" ).each {|f| require f }



