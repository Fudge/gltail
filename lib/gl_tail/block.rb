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
  config_attribute :auto_clean, "FIXME"
  config_attribute :activity_type, "FIXME"

  attr_accessor :column
  attr_reader   :config
  attr_reader   :max_rate

  def initialize(config, name)
    @config = config
    @name = name

    @size = 10
    @auto_clean = true
    @activity_type = "blobs"
    @order = 100

    @show = 0

    @header = Element.new(self, @name.upcase, [1.0, 1.0, 1.0, 1.0])

    @elements = { }
    @bottom_position = -@config.screen.top
    @max_rate = 1.0/599

    @sorted = []
    @updated = false
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
    return num if @elements.size == 0 || @sorted.size == 0

    @header.wy = top - (num * line_size)
    #    @header.y = @header.wy if @header.y == -$CONFIG.top
    @header.render(engine)
    num += 1

    count = 0

    @sorted.each do |e|
      engine.stats[0] += 1
      if count < @size
        e.wy = top - (num * line_size)
        e.render(engine)
        num += 1
        @max_rate = e.rate if e.rate > @max_rate
      else
        e.render_events(engine)
      end

      if e.activities.size == 0 && (e.rate <= 0.001 || count > 100) && @auto_clean
        @elements.delete(e.name)
        @sorted.delete(e)
      end
      count += 1
    end

    @bottom_position = top - ((@sorted.size > 0 ? (num-1) : num) * line_size)
    num + 1
  end

  def add_activity(options = { })
    return unless options[:name]
    x = nil
    unless @elements[options[:name]]
      x = Element.new(self, options[:name], @color || options[:color] )
      @elements[options[:name]] = x
      if @sorted.size > @size
        @sorted.insert(@size,x)
      else
        @sorted << x
      end
    else
      x = @elements[options[:name]]
    end
    x.add_activity(options[:message], @color || options[:color], options[:size] || 0.01, options[:type] || 0, options[:real_size] || options[:size] )
    @updated = true
  end

  def add_event(options = { })
    return unless options[:name]
    x = nil
    unless @elements[options[:name]]
      x = Element.new(self, options[:name], @color || options[:color] )
      @elements[options[:name]] = x
      if @sorted.size > @size
        @sorted.insert(@size,x)
      else
        @sorted << x
      end
    else
      x = @elements[options[:name]]
    end

    x.add_event(options[:message], options[:color] || @color, options[:update_stats] || false)
    @updated = true
  end

  def update
    return if @sorted.size == 0

    @max_rate = @max_rate * 0.9999

    startTime = Time.now

    i = 1
    @ordered = [@sorted[0]]
    min = @sorted[0].update
    size = @sorted.size

    while i < size
      rate = @sorted[i].update
      if rate > min
        j = i - 1
        while @ordered[j-1].rate < rate && j > 0
          j -= 1
        end
        @ordered.insert(j, @sorted[i])
      else
        @ordered << @sorted[i]
        min = rate if i < @size
      end
      i += 1
    end

    @sorted = @ordered

#    puts "#{@name} [#{@sorted.size}]: [#{Time.now - startTime}]" if @name == "urls"

    return

    return unless @updated

    sortTime = Time.now
#    iSort( @sorted )

#    @sorted = case @show
#              when 0: @sorted.insertionSort
#              when 1: @sorted.sort! { |k,v| "#{sprintf('%05d',v.total)} #{v.rate}" <=> "#{sprintf('%05d',k.total)} #{k.rate}" }
#              when 2: @sorted.sort! { |k,v| "#{v.average} #{v.name}" <=> "#{k.average} #{k.name}" }
#              end

    puts "#{@name} [#{@sorted.size}]: [#{sortTime - startTime}] [#{Time.now - sortTime}]"

    @updated = false

  end

end
