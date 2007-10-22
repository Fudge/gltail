#!/usr/bin/env ruby
# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)

$DBG=0
$VRB=1

file = 'config.yaml'

ARGV.each do |arg|
  case arg
  when '-help','--help','-h'
    puts "gl_tail.rb [--help|-h] [--parsers|-p] [--debug|-d] [--debug-ssh|-ds] [configfile]",
         '[--help|-h]        This help screen',
         '[--parsers|-p]     List available parsers',
         '[--options|-o]     List available configuration options',
         '[--debug|-d]       Turn on debugging',
         '[--debug-ssh|-ds]  Only debug SSH',
         '[configfile]       The YAML config file you wish to load (default = config.yaml)'
    exit
  when '-parsers','--parsers', '-p'
    @print_parsers = 1
  when '-debug', '--debug', '-d'
    $DBG=1
  when '-debug-ssh', '--debug-ssh', '-ds'
    $DBG=2
  when '--options', '-o'
    @print_options = 1
  else
    if File.exist? arg
      file = arg
    else
      file = "#{arg}.yaml"
    end
  end
end

require 'lib/gl_tail.rb'

if defined? @print_parsers
  puts "Supported Parsers [" + Parser::registry.keys.sort { |a,b| a.to_s <=> b.to_s }.collect{ |p| ":#{p.to_s}"}.join(", ") + "]"
  exit
end

if defined? @print_options
  puts "Supported Configuration Options"
  require 'pp'
  
  pp(GlTail::CONFIG_OPTIONS)
  exit
end


config = GlTail::Config.parse_yaml(file)

engine = GlTail::Engine.new(config)
engine.start
