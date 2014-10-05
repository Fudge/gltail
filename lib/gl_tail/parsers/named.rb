#-----------------------------------------------------------------------------------------------------------#
#  Example:      
#-----------------------------------------------------------------------------------------------------------#
#
#   - gl_tail.yaml config file:  
#
#     servers:
#       server_named:
#         host:     dns1.fooldns.com
#         files:    /var/log/named_querylog
#         parser:   named             
#         command:  tail -f -n0
#         user:     root    
#
#
#     - blocks:
#     
#       date        time                host      port        view              query          type
#       06-Oct-2014 00:16:40.464 client 127.0.0.1#42797 (vistafool): query: www.thefool.it IN A + (127.0.0.1)
#                
#                                                                                                          
#-----------------------------------------------------------------------------------------------------------#

class NamedParser < Parser
  def parse( line )
    _, date, time, host, port, view, query, type, type2, _ = /(\d+-\w+-\d+) (\d+:\d+:\d+\.\d+) client (\d+\.\d+\.\d+\.\d+)#(\d+) \((.+)\): query: (.*) (.*) (.*) (.*)/.match(line).to_a
    
    if host
      add_activity(block: 'sites', name: source.name)
      add_activity(block: 'hosts', name: host, size: 1)
      add_activity(block: 'types', name: "#{type} #{type2}")

      add_activity(:block => 'dns query', :name => query, :size => set_type_size(type))
      # add_activity(:block => 'port', :name => port, :size => 1, :type => 3)
      # add_activity(:block => 'time', :name => time, :size => 1, :type => 3)
      # add_activity(:block => 'view', :name => view, :size => 1, :type => 3)
      # user_id = Digest::MD5.hexdigest(host)
      # add_activity(:block => 'dns_user_id', :name => user_id, :size => set_type_size(type))
    end
    
  end   
       
  # you can use size to distinguish request types
  def set_type_size(type)
    case type
    when 'A' then 10
    when 'PTR' then 90
    when 'AAAA' then 70
    when 'TXT' then 60
    when 'SOA' then 50
    when 'MX' then 40
    when 'SRV' then 30
    when 'ANY' then 100
    else 
      150
    end
  end
end
