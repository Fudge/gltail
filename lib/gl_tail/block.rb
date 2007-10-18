# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

class Block
  include GlTail::Configurable

  attr_reader :name, :bottom_position

  config_attribute :color, "FIXME: add description", :type => :color
  config_attribute :order, "FIXME"
  config_attribute :size, "FIXME"
  config_attribute :auto_clean

  attr_accessor :column
  attr_reader :config

  def initialize(config, name)
    @config = config
    @name = name

    @size = 10
    @auto_clean = true
    @order = 100
#    @color = [1.0, 1.0, 1.0, 1.0]

    @show = 0

    @header = Element.new(self, @name.upcase)
    @header.color = [1.0, 1.0, 1.0, 1.0]

    @elements = { }
    @bottom_position = -@config.screen.top
  end

  def show=(value)
    @show = case value
    when 'rate' then 0
    when 'total' then 1
    when 'average' then 2
    else
      0
    end
  end

  attr_reader :show

  def top
    @config.screen.top
  end

  def line_size
    @config.screen.line_size
  end

  def is_right
    column.is_right
  end

  def alignment
    column.alignment
  end

  def position
    column.position
  end

  def width
    column.size
  end

  def render(engine, num)
    return num if @elements.size == 0

    @header.wy = top - (num * line_size)
    #    @header.y = @header.wy if @header.y == -$CONFIG.top
    @header.render(engine)
    num += 1

    sorted = case @show
    when 0: @elements.values.sort { |k,v| v.rate <=> k.rate}[0..@size-1]
    when 1: @elements.values.sort { |k,v| v.total <=> k.total}[0..@size-1]
    when 2: @elements.values.sort { |k,v| v.average <=> k.average}[0..@size-1]
    end

    sorted.each do |e|
      e.wy = top - (num * line_size)
      e.render(engine)
      engine.stats[0] += 1
      if e.rate <= 0.0001 && e.active && e.updates > 59 && @auto_clean
        @elements.delete(e.name)
      end
      num += 1
    end

    (@elements.values - sorted).each do |e|
      engine.stats[0] += 1
      e.activities.each do |a|
        a.render(engine)
        if a.x > 1.0 || a.x < -1.0 || a.y > @config.screen.aspect
          e.activities.delete a
        end
      end
      if e.activities.size == 0 && @auto_clean && e.updates > 59
        @elements.delete(e.name)
      end
    end
    @elements.delete_if { |k,v| (!sorted.include? v) && v.active && v.activities.size == 0 && v.updates > 29} if @auto_clean
    @bottom_position = top - ((sorted.size > 0 ? (num-1) : num) * line_size)
    num + 1
  end

  def add_activity(options = { })
    x = @elements[options[:name]] ||= Element.new(self, options[:name])
    x.add_activity(options[:message], @color || options[:color] , options[:size] || 0.01, options[:type] || 0 )
  end

  def add_event(options = { })
    x = @elements[options[:name]] ||= Element.new(self, options[:name])
    x.add_event(options[:message], options[:color] || @color, options[:update_stats] || false)
  end

  def update
    @elements.each_value do |e|
      e.update
    end
  end
end
