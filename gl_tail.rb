#!/usr/bin/env ruby
# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)

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
    @print_parsers = 1
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

  require 'yaml'

  def initialize file
    file  ||= "config.yaml"
    @yaml   = YAML.load_file(file)
    @left   = Hash.new
    @right  = Hash.new
    @blocks = Array.new

    parse_servers
    parse_config
  end

  def method_missing method, *arg
    method = method.to_s
    if method.delete! '='
      instance_variable_set "@#{method}", arg.first
    else
      instance_variable_get "@#{method.to_s}"
    end
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
        elsif key == 'highlight_color'
          self.highlight_color = parse_color config
        elsif key == 'bounce'
          self.bounce = ( value == 'true' ? true : false )
        else
          eval "self.#{key} = #{config}"
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
    @colors = {
      'white'   => %w{ 255 255 255 255 },
      'red'     => %w{ 255   0   0 255 },
      'green'   => %w{   0 255   0 255 },
      'blue'    => %w{   0   0 255 255 },
      'yellow'  => %w{ 255 255   0 255 },
      'cyan'    => %w{   0 255 255 255 },
      'magenta' => %w{ 255   0 255 255 },

      'purple'  => %w{ 128   0 255 255 },
      'orange'  => %w{ 255 128   0 255 },
      'pink'    => %w{ 255   0 128 255 },
    }

    case v
    when /(.+),(.+),(.+),(.+)/
      value = v.split(',')
    else
      value = @colors[v.downcase]
      unless value
        raise SyntaxError, "You must use either [#{@colors.keys.sort.join('|')}] or a color in RGBA format."
        exit
      end
      value.map! { |x| x.to_i / 255.0 }
    end
    value.map {|x| x.to_f }
  end
end

$CONFIG = Configuration.new $CONFIG

require 'lib/gl_tail.rb'

if defined? @print_parsers
  puts "Supported Parsers [" + Parser::registry.keys.sort { |a,b| a.to_s <=> b.to_s }.collect{ |p| ":#{p.to_s}"}.join(", ") + "]"
  exit
end

GlTail.new.start
