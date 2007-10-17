# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles tshark logs
class TSharkParser < Parser

  def parse( line )
    if(line.include?('->'))
      time, srcip, arrow, destip, type, = line.split(" ")
      add_activity(:block => 'users', :name => srcip)
      add_activity(:block => 'types', :name => type)
    end

    if(line.include?('DNS Standard query A'))
      foo, name = line.split(" A ")
      if(name != nil)
        add_event(:block => 'status', :name => "DNS Queries", :message => "DNS Request: " + name, :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0])
      end
    end 
  end 
    
end
