#!/usr/bin/env ruby
# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#
# Further ideas:
#   Get rid of glutBitmapCharacter and use textured polygons instead
#   Allow more indicators (pulsing color/size, cubes, teapots, etc)
#   Clickable links
#   Drag 'n drop organizing
#   Hide/show blocks with keypresses
#   Limit display to specific host
#   Background IP lookups
#   Geolocation on IPS
#


$DBG=0

require 'config.rb'
require 'lib/gl_tail.rb'

ARGV.each do |arg|
  case arg
  when '-help','--help','-h'
    puts "gl_tail.rb [--help|-h] [--parsers|-p] [--debug|-d] [--debug-ssh|-ds] [configfile]"
    exit
  when '-parsers','--parsers', '-p'
    puts "Supported Parsers [" + Parser::registry.keys.sort { |a,b| a.to_s <=> b.to_s }.collect{ |p| ":#{p.to_s}"}.join(", ") + "]"
    exit
  when '-debug', '--debug', '-d'
    $DBG=1
  when '-debug-ssh', '--debug-ssh', '-ds'
    $DBG=2
  else
    require arg
  end

end

require 'yaml'
$SERVERS = Array.new unless $SERVERS
servers = YAML.load_file($SERVER_YAML_FILE)
servers.inspect
servers.each do |server|
  hash = {:name => server.shift}
  server.flatten[0].each do |key, value|
    if key == 'files'
      hash2 = {key.to_sym, value.split(',')}
    elsif key == 'color'
      hash2 = {key.to_sym, value.split(',').map {|x| x.to_f}}
    elsif key == 'parser'
      hash2 = {key.to_sym, value.to_sym}
    else
      hash2 = {key.to_sym, value}
    end
    hash.merge!(hash2)
  end
  $SERVERS << hash
end

GlTail.new.start
