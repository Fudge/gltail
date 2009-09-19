# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles Nanite logs
class NaniteParser < Parser

  def parse(line)
    if line =~ /SEND/
      if matchdata = line.scan(/\/(.*)$/)[0]
        # Calm gray for the offline persistent ones, orange for the rest..
        color = line =~ /offline.failsafe/ ? Array.new(4, 0.7) :  [1.0, 0.4, 0.2, 1.0]
        add_activity(:block => 'mappers', :name => matchdata[0], :size => 0.01, :color => color)
      end
    # RECV only appears on debug mode...
    elsif line =~ /RECV/
      if matchdata = line.scan(/\/(.*) from mapper, target (.*), payload (.*)/)[0]
        add_activity(:block => "agents", :name => matchdata[1], :message => "#{matchdata[0]} to #{matchdata[1]}", :size => 0.005)
      end
    elsif line =~ /Error \(/
      add_activity(:block => "warnings", :name => line)
    end
  end
  # eval the payload .. TODO?

end
