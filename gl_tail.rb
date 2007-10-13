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
    if File.exist? arg
      $CONFIG = arg
    else
      $CONFIG = "#{arg}.yaml"
    end
  end

end

######## LOAD YAML CONFIG FILE ###########
require 'yaml'

yaml = YAML.load_file($CONFIG || 'config.yaml')
# Parse servers first
$SERVERS = Array.new unless $SERVERS
yaml['servers'].each do |server|
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

# Now configs
yaml['config'].each do |key, config|
  unless config.is_a? Hash
    if key == 'dimensions'
      $WINDOW_WIDTH, $WINDOW_HEIGHT = config.split('x').map{|x| x.to_f}
    else
      eval "$#{key.upcase} = #{config.to_f}"
    end
  else
    if key == 'left_column'
      config.each do |key, left_column|
        case key
        when 'size'
          $COLUMN_SIZE_LEFT = left_column.to_int
        when 'alignment'
          $LEFT_COL = left_column.to_f
        when 'blocks'
          $BLOCKS = Array.new unless $BLOCKS
          left_column.each do |block, value|
            hash = {:name => block}
            value.each do |key, value|
              case key
              when 'size'
                value = value.to_f
              when 'show'
                value = value.to_sym
              when 'auto_clean'
                value = ( value == 'true' ? true : false )
              when 'color'
                value = value.split(',').map {|x| x.to_f}
              when 'order'
                value = value.to_int
              end
              hash.merge!({key.to_sym => value})
            end
            h2 = {:position => :left}
            hash.merge! h2
            $BLOCKS << hash
          end
        end
      end
    elsif key == 'right_column'
      config.each do |key, right_column|
        case key
        when 'size'
          $COLUMN_SIZE_RIGHT = right_column.to_int
        when 'alignment'
          $RIGHT_COL = right_column.to_f
        when 'blocks'
          $BLOCKS ||= Array.new
          right_column.each do |block, value|
            hash = {:name => block}
            value.each do |key, value|
              case key
              when 'size'
                value = value.to_f
              when 'show'
                value = value.to_sym
              when 'auto_clean'
                value = ( value == 'true' ? true : false )
              when 'color'
                value = value.split(',').map {|x| x.to_f}
              when 'order'
                value = value.to_int
              end
              hash.merge!({key.to_sym => value})
            end
            h2 = {:position => :right}
            hash.merge! h2
            $BLOCKS << hash
          end
        end
      end
    end
  end
end

GlTail.new.start
