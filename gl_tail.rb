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

ARGV.each do |arg|
  case arg
  when '-help','--help','-h'
    puts "gl_tail.rb [--help|-h] [--parsers|-p] [--debug|-d] [--debug-ssh|-ds] [configfile]",
         '[--help|-h]        This help screen',
         '[--parsers|-p]     List available parsers',
         '[--debug|-d]       Turn on debugging',
         '[--debug-ssh|-ds]  Only debug SSH',
         '[configfile]       The YAML config file you wish to load (default = config.yaml)'
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
# Parse servers first

# Now configs

class Configuration
  attr_reader :yaml
  attr_accessor :servers, :window_width, :window_height, :left, :right, :blocks, :wanted_fps, :top, :min_blob_size, :max_blob_size, :line_size, :aspect, :stats, :bitmap_mode, :dbg
  require 'yaml'
  def initialize file = 'config.yaml'
    @yaml   = YAML.load_file(file)
    @left   = Hash.new
    @right  = Hash.new
    @blocks = Array.new

    parse_servers
    parse_config
  end
  
  def parse_servers
    self.servers = Array.new
    self.yaml['servers'].each do |server|
      hash = {:name => server.shift}
      server.flatten[0].each do |key, value|
        case key
        when 'files'
          value = value.split(',')
        when 'color'
          value = parse_color value
        when 'parser'
          value = value.to_sym
        end
        hash2 = {key.to_sym => value}
        hash.merge!(hash2)
      end
      self.servers << hash
    end
  end
  
  def parse_config
    self.yaml['config'].each do |key, config|
      unless config.is_a? Hash
        if key == 'dimensions'
          self.window_width, self.window_height = config.split('x').map{|x| x.to_f}
        else
          if self.respond_to? key
            instance_variable_set "@#{key}", config.to_f
          end
          # TODO: Right now we ignore it if its not set right now. Maybe throw a SyntaxError?
        end
      else
        if key == 'right_column'
          parse_column :right
        elsif key == 'left_column'
          parse_column :left
        end
      end
    end
  end
  
  def parse_column which
    self.yaml['config']["#{which.to_s}_column"].each do |key, column|
      case key
      when 'size'
        # $CONFIG.right[:alignment]UMN_WIDTH
       self.setter which, column.to_int, :size
      when 'alignment'
        # $CONFIG.right[:alignment]
        self.setter which, column.to_f, :alignment
      when 'blocks'
        column.each do |block, value|
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
              value = parse_color value
            when 'order'
              value = value.to_int
            end
            hash.merge!({key.to_sym => value})
          end
          h2 = {:position => which}
          hash.merge! h2
          self.blocks << hash
        end
      end
    end
  end
  
  def setter variable, value, which
    eval "self.#{variable.to_s}[:#{which}] = #{value}"
  end
  
  def parse_color v
    case v
    when /(.+),(.+),(.+),(.+)/
      value = v.split(',')
    when 'white'
      value = %w{ 255 255 255 1 }
    when 'red'
      value = %w{ 255 0 0 1 }
    when 'green'
      value = %w{ 0 255 0 1 }
    when 'blue'
      value = %w{ 0 0 255 1 }
    when 'yellow'
      value = %w{ 255 255 0 1 }
    when 'cyan'
      value = %w{ 0 255 255 1 }
    when 'magenta'
      value = %w{ 255 0 255 1 }
    else
      raise SyntaxError, 'You must give either a accepted color or a color in RGBA format. Accepted colors are: white, red, green, blue, yellow, cyan or magenta'
      exit
    end
    value.map {|x| x.to_f}
  end
end

$CONFIG = Configuration.new $CONFIG

require 'lib/gl_tail.rb'

GlTail.new.start
