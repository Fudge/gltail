# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles Rails access logs
class RailsParser < Parser
  def parse( line )
    #Completed in 0.02100 (47 reqs/sec) | Rendering: 0.01374 (65%) | DB: 0.00570 (27%) | 200 OK [http://example.com/whatever/whatever]
    _, ms, url = /^Completed in ([\d.]+) .* \[([^\]]+)\]/.match(line).to_a

    if url
      _, host, url = /^http[s]?:\/\/([^\/]*)(.*)/.match(url).to_a

      add_activity(:block => 'sites', :name => host, :size => ms.to_f) # Size of activity based on request time.
      add_activity(:block => 'urls', :name => HttpHelper.generalize_url(url), :size => ms.to_f)
      add_activity(:block => 'slow requests', :name => HttpHelper.generalize_url(url), :size => ms.to_f)
      add_activity(:block => 'content', :name => 'page')

      # Events to pop up
      add_event(:block => 'info', :name => "Logins", :message => "Login...", :update_stats => true, :color => [0.5, 1.0, 0.5, 1.0]) if url.include?('/login')
      add_event(:block => 'info', :name => "Sales", :message => "$", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if url.include?('/checkout')
      add_event(:block => 'info', :name => "Signups", :message => "New User...", :update_stats => true, :color => [1.0, 1.0, 1.0, 1.0]) if(url.include?('/signup') || url.include?('/users/create'))
    elsif line.include?('Processing ')
      #Processing TasksController#update_sheet_info (for 123.123.123.123 at 2007-10-05 22:34:33) [POST]
      _, host = /^Processing .* \(for (\d+.\d+.\d+.\d+) at .*\).*$/.match(line).to_a
      if host
        add_activity(:block => 'users', :name => host)
      end
    elsif line.include?('Error (')
      _, error, msg = /^([^ ]+Error) \((.*)\):/.match(line).to_a
      if error
        add_event(:block => 'info', :name => "Exceptions", :message => error, :update_stats => true, :color => [1.0, 0.0, 0.0, 1.0])
        add_event(:block => 'info', :name => "Exceptions", :message => msg, :update_stats => false, :color => [1.0, 0.0, 0.0, 1.0])
        add_activity(:block => 'warnings', :name => msg)

      end
    end
  end
end
