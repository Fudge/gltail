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
#       01-Jul-2009 00:12:34.567 client 127.0.0.1#37534: view vistafool: query: www.thefool.it IN A +E
#                
#                                                                                                          
#-----------------------------------------------------------------------------------------------------------#

class NamedParser < Parser
  def parse( line )
    _, date, time, host, port, view, query, type, type2 = /(\d+-\w+-\d+) (\d+:\d+:\d+\.\d+) client (\d+\.\d+\.\d+\.\d+)#(\d+): view (.+): query: (.*) (.*) (.*) (.*)/.match(line).to_a
    
    if host                                                                        
      add_activity(:block => 'time', :name => time, :size => 1, :type => 3)         
      add_activity(:block => 'host', :name => host, :size => 1, :type => 3)     
      add_activity(:block => 'port', :name => host, :size => 1, :type => 3)
      add_activity(:block => 'view', :name => host, :size => 1, :type => 3)   
      user_id = Digest::MD5.hexdigest(host)                                       
      add_activity(:block => 'dns_user_id', :name => user_id, :size => set_type_size(type))
      add_activity(:block => 'query', :name => host, :size => set_type_size(type))   
      add_activity(:block => 'type', :name => "#{type} #{type2}", :type => 3)
    end
    
  end   
       
  # you can use size to distinguish request types
  def set_type_size(type)
    set_size = case type
    when "A"     : 10
    when "PTR"   : 90
    when "AAAA"  : 70
    when "TXT"   : 60
    when "SOA"   : 50
    when "MX"    : 40
    when "SRV"   : 30
    when "ANY"   : 100
    else 
      150
    end
  end
end