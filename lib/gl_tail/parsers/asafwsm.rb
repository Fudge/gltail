# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser for ASA logs
# Jeff Bryner (jeff@jeffbryner.com)
# inspired by pix parser by Leif Sawyer (leif@denali.net)


#assumptions: 
#you've named your interfaces
#no name resolution on ports or ips from the asa, i.e. it spits out just dotted ips and port numbers.


#fields for use in your .yaml file.
#action: Deny
#ipprotocol: tcp,udp,icmp
#sourceinterface: whatever you've named the interface in your ASA
#sourcehost: source host in the message
#sourceport: source port in the message
#destinationinterface: whatever you've named the interface in your ASA
#destinationhost: destination host in the message
#destinationport: destination port in the message

class ASAParser < Parser
  def parse( line )
    #note: 
    #the built/accessed urls are left over from Leif's pix parser. 
    #I don't log build/teardowns/urls on my asa's so I've no idea if these still work.

    if line.include?(': Built')
        _, firewall, type, direction, srcif, src, srcport, dstif, dst, dstport =
               /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: Built (\w+)bound \w+ connection \d+ for (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+) \(.*\) to (\w+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9.]+)/.match(line).to_a

        if firewall
          add_activity(:block => 'firewall', :name => firewall)
          if direction == 'out'
            add_activity(:block => 'hosts', :name => src)
            add_activity(:block => 'sites', :name => dst)
          else
            add_activity(:block => 'hosts', :name => dst)
            add_activity(:block => 'sites', :name => src)
          end
          printf("%sbound from %s firewall '%s', srcif=%s, src=%s, srcport=%s, dstif=%s, dst=%s, dstport=%s...\n", direction, type, firewall, srcif, src, srcport, dstif, dst, dstport ) if $VRB > 0
        end

    elsif line.include?('Accessed URL')
          _, firewall, type, client, server, url = /^.* \d+ \d+:\d+:\d+ \[?([a-zA-Z0-9\-]+)\/?\]?.* %(FWSM|PIX)-\d+-\d+: ([a-zA-Z0-9.]+) Accessed URL ([a-zA-Z0-9.]+):(.*)[\?]?/.match(line).to_a
        if firewall
          add_activity(:block => 'firewall', :name => firewall)
          add_activity(:block => 'hosts', :name => client)
          add_activity(:block => 'sites', :name => server)
          add_activity(:block => 'urls', :name => url)
          printf("%s firewall '%s': client %s accessed url %s on host %s\n", type, firewall, client, url, server) if $VRB > 0
        end

    elsif line.include?('106023: Deny')
	#%ASA-4-106023: Deny udp src LAN:10.2.12.34/54237 dst INTERNET:200.116.129.91/54277 by access-group "LAN_acl" [0x12add511, 0x8cf14848]

	_,ipprotocol,sourceinterface,sourcehost,sourceport,destinationinterface,destinationhost,destinationport=/Deny (\S+) src (\S+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9]+) dst (\S+):([a-zA-Z0-9.]+)\/([a-zA-Z0-9]+)/.match(line).to_a
	ipprotocol=ipprotocol.upcase
	add_activity(:block=> 'action',:name=>'Deny',:type => 3)#don't create a bouncing blob.
	add_activity(:block=> 'ipprotocol',:name=>ipprotocol,:type => 3)
	add_activity(:block=> 'sourcehost',:name=>sourcehost,:type => 1)	
	add_activity(:block=> 'sourceinterface',:name=>sourceinterface,:type => 3)
	add_activity(:block=> 'sourceport',:name=>sourceport,:type => 3)
	add_activity(:block=> 'destinationhost',:name=>destinationhost,:type => 5)	
	add_activity(:block=> 'destinationinterface',:name=>destinationinterface,:type => 3)
	add_activity(:block=> 'destinationport',:name=>destinationport,:type => 2,:message=>destinationport)
        #printf("asa-106023: host: %s, protocol: %s, sourcport %s, 106023 Deny: %s \n",sourcehost,protocol,sourceport,line) if $VRB > 0

    elsif line.downcase.match('denied|deny|discarded|no translation group')
    	#catch all for the myriad of cisco messages such as:
    	#	ASA-2-106001: Inbound TCP connection denied from 10.21.144.12/8076 to 192.168.21.15/3360 flags SYN ACK  on interface LAN
	#	ASA-3-305005: No translation group found for icmp src DMZ:192.168.244.236 dst INTERNET:17.9.239.251 (type 0, code 0)	
	#etc, without specific message by message parsing.

	#uncomment for debug
	#printf("asa catchall: %s \n",line) if $VRB > 0
		
	#find the protocol
	ipprotocol=line.upcase.scan(/(TCP|UDP|ICMP)/)[0].join
	
	#sourceinterface?
	sourceinterface=line.scan(/on interface (\S+)/)
	if sourceinterface.length>0
		sourceinterface=sourceinterface[0].join
	else
		sourceinterface='unknown'
	end

	#get ips , first is the source, second is dest
	hosts=line.scan(/((?:\d{1,3}\.){3}\d{1,3})/)
	sourcehost=hosts[0].to_s
	destinationhost=hosts[1].to_s
	
	#get source port, just after the first ip address and the slash 
	sourceport=line.scan(/#{sourcehost}\/([a-zA-Z0-9]+)/)
	if sourceport.length>0
		sourceport=sourceport[0].join
	else
		sourceport='0'
	end
	

	#get dest port, just after the ip address and the slash 
	destinationport=line.scan(/#{destinationhost}\/([a-zA-Z0-9]+)/)
	if destinationport.length>0
		destinationport=destinationport[0].join
	else
		destinationport='0'
	end
	
	#try the interfaces again if there in front of the ip like interface:ipaddress/port
	if sourceinterface=='unknown'
		sinterface=line.scan(/ ([a-zA-Z0-9]+)\:#{sourcehost}/)
		if sinterface.length>0
			sourceinterface=sinterface[0].join
		end
	end

	dinterface=line.scan(/ ([a-zA-Z0-9]+)\:#{destinationhost}/)
	if dinterface.length>0
		destinationinterface=dinterface[0].join
	else
		destinationinterface='unknown'
	end
	

	add_activity(:block=> 'action',:name=>'Deny',:type => 3)			#type 3 doesn't create a bouncing blob.
	add_activity(:block=> 'ipprotocol',:name=>ipprotocol,:type => 3)
	add_activity(:block=> 'sourcehost',:name=>sourcehost,:type => 1)		#type 1 seems to draw the source blob, headed from a host
	add_activity(:block=> 'sourceinterface',:name=>sourceinterface,:type => 3)
	add_activity(:block=> 'sourceport',:name=>sourceport,:type => 3)
	add_activity(:block=> 'destinationhost',:name=>destinationhost,:type => 5)	#type 5 seems to draw a target blob--i.e. headed towards the host
	add_activity(:block=> 'destinationport',:name=>destinationport,:type => 2,:message=>destinationport)	#type 2 seems to draw text, space invaders style cascading down the screen
		
    	#add_event(:block=>'info',:name=>ipprotocol,:message=>line,:update_stats => true, :color => [1.5, 1.0, 0.5, 1.0])

	#uncomment these for debugging
	#printf("sourcehost/port: %s/%s \n",hosts[0],sourceport) if $VRB > 0
	#printf("destinationhost/port: %s/%s \n",hosts[1],destinationport) if $VRB > 0	
	#printf("sourceinterface: %s\n",sourceinterface) if $VRB>0
	#printf("destinationinterface: %s\n",destinationinterface) if $VRB>0

     else
     	printf("skipped: %s\n",line)if $VRB > 0

    end
 end
end
