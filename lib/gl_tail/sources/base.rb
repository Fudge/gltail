

module GlTail
  module Source
    
    class Base
      include GlTail::Configurable

      attr_accessor :name

      def initialize(config)
        @config = config
      end

      attr_reader :parser, :config
      
      config_attribute :color, 'FIXME', :type => :color
      
      def parser=(name)
        if klass = Parser.registry[name.to_sym]
          @parser = klass.new(self)
        else
          raise "Couldnt find a Parser by name: #{name}, try --parsers for a list of available parsers"
        end
      end
      
      def process
        raise "#{self.class.to_s} does not implement .process"
      end
      
      def update
        raise "#{self.class.to_s} does not implement .update"
      end
    
      def add_activity( opts = {} )
        @config.add_activity( self, opts )
      end

      def add_event( opts = {} )
        @config.add_event( self, opts )
      end    
    end
  end
end
