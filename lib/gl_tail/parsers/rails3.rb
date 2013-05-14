# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles Rails 3 access logs
class Rails3Parser < Parser
  def parse( line )
    case(line)
    when /^Started (GET|POST|PUT|DELETE) "(.*)" for (\d+\.\d+\.\d+\.\d+) at .*$/
      add_activity(:block => 'urls', :name => HttpHelper.generalize_url($2))
      add_activity(:block => 'users', :name => $3)
      add_activity(:block => 'content', :name => 'page')
    when matchdata = /^Completed (\d\d\d) .* in (\d+)ms/
      # Completed 200 OK in 4659ms (Views: 3376.3ms | ActiveRecord: 0.0ms)
      size = $2.to_f/1000
      add_activity(:block => 'status', :name => $1, :size => size)
      add_activity(:block => 'sites', :name => server.name, :size => size)
    when matchdata = /^([^ ]+Error) \((.*)\):/
      add_event(:block => 'info', :name => "Exceptions", :message => $1, :update_stats => true, :color => [1.0, 0.0, 0.0, 1.0])
      add_event(:block => 'info', :name => "Exceptions", :message => $2, :update_stats => false, :color => [1.0, 0.0, 0.0, 1.0])
      add_activity(:block => 'warnings', :name => $2)
    end
  end
end
