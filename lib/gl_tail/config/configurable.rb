module GlTail

  module Configurable

    module ClassMethods
      def config_attribute(id, description = "", opts = {})

        rewrite_method = case opts[:type]
        when :color
          "config_rewrite_color"
        else
          ""
        end

        self.class_eval %{
          def #{id}=(value)
            @#{id} = #{rewrite_method} value
          end

          def #{id}
            @#{id}
          end
        }

        doc = GlTail::CONFIG_OPTIONS[self.to_s] ||= {}
        doc[id] = {
          :description => description,
        }.update(opts)        
      end
    
    end

    def config_rewrite_color(v)
      case v
      when /(.+),(.+),(.+),(.+)/
        value = v.split(',')
      else
        value = GlTail::COLORS[v.downcase]
        unless value
          raise SyntaxError, "You must use either [#{GlTail::COLORS.keys.sort.join('|')}] or a color in RGBA format."
        end
        value.map! { |x| x.to_i / 255.0 }
      end
      value.map {|x| x.to_f }
    end

    def self.included(receiver)
      receiver.extend ClassMethods
    end
  end
end