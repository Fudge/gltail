# this redirection script by John Mair (banisterfiend)

require 'rbconfig'

direc = File.dirname(__FILE__)
dlext = RbConfig::CONFIG['DLEXT']
require "#{direc}/chipmunk.#{dlext}"


# Add some constants to CP here, so we don't need 
# to do it in the C code.
# Let's cheat a bit here.. :p

module CP
  VERSION    = '5.4.3' 
  ZERO_VEC_2 = Vec2.new(0,0).freeze
  ALL_ONES   = Vec2.new(1,1).freeze
end  
 
# Extra functionality added by Slembkce and Beoran.

module CP
  # Chipmunk Object
  # Makes it easier to manage complex objects that reference many primitive
  # Chipmunk objects such as bodies shapes and constraints.
  # New composite objects simply need to include CP::Object and call
  # init_chipmunk_object(*objects) with the composite and primitive Chipmunk
  # objects that make up itself.
  module Object
    # Returns the list of primitive Chipmunk objects (bodies, shapes and
    # constraints that this composite object references directly and indirectly.
    def chipmunk_objects
      if @chipmunk_objects
        return @chipmunk_objects
      else
        raise "This CP::Object (#{self.class}) did not call #init_chipmunk_object."
      end
    end
    
    private
    # Should be called during initialization of a CP::Object to set what primitive
    # and composite Chipmunk objects this object references.
    def init_chipmunk_object(*objs)
      bad_objs = objs.reject{|obj| obj.is_a?(CP::Object)}
      unless bad_objs.empty?
        raise(ArgumentError, "The following objects: #{bad_objs.inspect} are not CP::Objects")
      end
      @chipmunk_objects = objs.inject([]){|sum, obj| sum + obj.chipmunk_objects}.uniq
    end
  end
  
  class Body
    include CP::Object

    def chipmunk_objects
      [self]
    end
    
    def add_to_space(space)
      space.add_body(self)
    end
    
    def remove_from_space(space)
      space.remove_body(self)
    end
    
  end
  
  module Shape
    include CP::Object
    
    def chipmunk_objects
      [self]
    end
    
    def add_to_space(space)
      space.add_shape(self)
    end
    
    def remove_from_space(space)
      space.remove_shape(self)
    end
  end
    
  module Constraint
    include CP::Object
    
    def chipmunk_objects
      [self]
    end
    
    def add_to_space(space)
      space.add_constraint(self)
    end
    
    def remove_from_space(space)
      space.remove_constraint(self)
    end
  end
  
  class Space
    def add_object(obj)
      obj.chipmunk_objects.each{|elt| elt.add_to_space(self)}
    end
    
    def add_objects(*objs)
      objs.each{|obj| add_object(obj)}
    end
    
    def remove_object(obj)
      obj.chipmunk_objects.each{|elt| elt.remove_from_space(self)}
    end
    
    def remove_objects(*objs)
      objs.each{|obj| remove_object(obj)}
    end
    
  end
  
  class Vec2
    ZERO = Vec2.new(0,0).freeze
  end
  
  # define the helpers here( easier than in the extension.
  class SegmentQueryInfo
    def hit_point(start, stop)
      return start.lerp(stop, self.t)
    end
    
    def hit_dist(start, stop)
      return start.dist(stop) * self.t
    end
  end  
  
  
end


# Create derived static objects that know to add themselves as static.
module CP
  class BodyStatic < Body
    def initialize
      super(Float::INFINITY, Float::INFINITY)
    end
    
    def chipmunk_objects
      # return [] instead of [self] so the static body will not be added.
      []
    end
  end
  
  class StaticBody
    def chipmunk_objects
      # return [] instead of [self] so the static body will not be added.
      []
    end
  end
  
  module StaticShape
    include Shape
    
    class Circle < Shape::Circle
      include StaticShape
    end
    
    class Segment < Shape::Segment
      include StaticShape
    end
    
    class Poly < Shape::Poly
      include StaticShape
    end

    def add_to_space(space)
      space.add_static_shape(self)
    end
    
    def remove_from_space(space)
      space.remove_static_shape(self)
    end
  end
end
 



