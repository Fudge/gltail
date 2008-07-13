
module GlTail
  module Source

    class Local < Base
      config_attribute :source, "The type of Source"
      config_attribute :host
      config_attribute :files, "The files to tail", :deprecated => "Should be embedded in the :command"

        def init
            @log = File.open(files)
            @log.extend(File::Tail)
            @log.max_interval = 5
            @log.return_if_eof = true
        end
      
        def process
          @log.tail(1) { |line|
            parser.parse(line) 
          }
        end
        
        def update
        end
        
    end
  end
end
