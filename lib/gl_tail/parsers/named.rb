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
  def parse(line)
    case line.to_s
      when /(\d+-\w+-\d+) (\d+:\d+:\d+\.\d+) client (?<host>\d+\.\d+\.\d+\.\d+)#(\d+) \((.+)\): query: (?<query>.+) (?<type>\S+) (?<type2>\S+) \((.*)\)/
        add_activity(block: 'sites',     name: source.name)
        add_activity(block: 'types',     name: "#{$~[:type]} #{$~[:type2]}")
        add_activity(block: 'hosts',     name: $~[:host],  size: 1)
        add_activity(block: 'dns query', name: $~[:query], size: set_type_size($~[:type]))
      else
        # ...
    end
  end   
       
  # you can use size to distinguish request types
  def set_type_size(type)
    @type_size ||= {A: 30, SRV: 40, MX: 50, SOA: 60, TXT: 70, AAAA: 80, PTR: 90, ANY: 100}
    @type_size[type.to_sym]||150
  end
end
