require 'yaml'

module GlTail
  class YamlParser
    attr_reader :yaml

    def initialize file
      file  ||= "config.yaml"
      @yaml   = YAML.load_file(file)
    end

    def apply(config)
      @config = config

      @left   = Hash.new
      @right  = Hash.new
      @blocks = Array.new

      parse_servers
      parse_config

      @config
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

        src = GlTail::Source::SSH.new(@config)

        src.name = server.shift

        apply_values(src, server.shift)

        @config.sources << src
      end
    end

    def apply_values(target, hash)
      hash.each do |key, value|
        apply_value(target, key, value)
      end
    end

    def apply_value(target, key, value)
      begin
        target.send("#{key}=", value)
      rescue
        puts "FAILED TO APPLY #{key}=#{value} TO #{target}"
        raise
      end
    end

    def parse_config
      self.yaml['config'].each do |key, config|
        screen = @config.screen

        case config
        when Hash
          if key =~ /(left|right)_column/
            column = screen.send($1)
            blocks = config.delete('blocks')

            apply_values(column, config)
            add_blocks(column, blocks)
          else
            target = screen.send(key)          
            apply_values(target, config)
          end
        else
          apply_value(screen, key, config)
        end
      end
    end

    def add_blocks(column, hash)
      hash.each do |key, config|
        block = @config.add_block(key)
        block.column = column
        
        apply_values(block, config)
      end
    end
  end
end
