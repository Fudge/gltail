# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2011 Guillaume Hain <zedtux@zedroot.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles Rails access syslogs
class RailsSyslogParser < Parser
  def parse( line )
    #Apr 18 07:27:02 appname network_name[pid]: Completed in 0.02100 (47 reqs/sec) | Rendering: 0.01374 (65%) | DB: 0.00570 (27%) | 200 OK [http://example.com/whatever/whatever]
    _, ms, url = /^.*\[[\d.]+\]: Completed in ([\d.]+)ms .* \[([^\]]+)\]/.match(line).to_a

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
      #Apr 18 07:27:02 appname network_name[pid]: Processing TasksController#update_sheet_info (for 123.123.123.123 at 2007-10-05 22:34:33) [POST]
      _, host = /^.*: Processing .* \(for (\d+.\d+.\d+.\d+) at .*\).*$/.match(line).to_a
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
    elsif line.include?('SELECT ')
      #Apr 18 07:27:02 appname network_name[pid]: IsinTarget Load (1.1ms)   SELECT * FROM "table" WHERE id = 1
      _, model_name, ms = /^.*\[[\d.]+\]: ([A-Za-z]+) Load \(([\d.]+)ms\)[\s]+SELECT.*$/.match(line).to_a
      
      add_activity(:block => 'sqlselect', :name => model_name, :size => ms.to_f)
    elsif line.include?('UPDATE ')
      #Apr 18 07:27:02 appname network_name[pid]: IsinTarget Load (1.1ms)   UPDATE "table" SET "column" = 'value' WHERE id = 1
      _, model_name, ms = /^.*\[[\d.]+\]: ([A-Za-z]+) Update \(([\d.]+)ms\)[\s]+UPDATE.*$/.match(line).to_a
      
      add_activity(:block => 'sqlupdate', :name => model_name, :size => ms.to_f)
    elsif line.include?('INSERT INTO ')
      #Apr 18 07:27:02 appname network_name[pid]: SQL (3.0ms)   INSERT INTO "table" ("field1", "field2") VALUES(value1, value2) RETURNING "id"
      _, ms, table_name = /^.*\[[\d.]+\]: SQL \(([\d.]+)ms\)[\s]+INSERT INTO \"([A-Za-z_]+)\".*$/.match(line).to_a
      
      add_activity(:block => 'sqlinsert', :name => table_name, :size => ms.to_f)
    end
  end
end
