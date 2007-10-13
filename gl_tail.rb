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


require 'config.rb'
require 'lib/gl_tail.rb'

ARGV.each do |arg|
  case arg
  when '-help','--help'
    puts "gl_tail.rb [-help|-parsers] [configfile]"
    exit
  when '-parsers','--parsers'
    puts "Supported Parsers [" + Parser::registry.keys.sort { |a,b| a.to_s <=> b.to_s }.collect{ |p| ":#{p.to_s}"}.join(", ") + "]"
    exit
  else
    require arg
  end

end




GlTail.new.start
