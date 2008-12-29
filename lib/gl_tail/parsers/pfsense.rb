# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser for PF Logs, specifically those from pfSense (1.2.1)
# Jim Pingle (myfirstname@pingle.org)

# Available Blocks 
#action: block|pass
#rule: Rule number matched
#proto: carp|icmp|tcp|udp|ah|igmp|esp|gre you get the idea..
#int: This will be the actual interface (fxp0, vlan2, em1, etc) as the 'friendly' name is not put in the logs.
#srchost: source host/IP
#srcport: source port
#dsthost: destination host/IP
#dstport: destination port
#srcdst:  source host and port > destination host and port

class PFSenseParser < Parser
  require 'date'
  
  def getipandport(hostwithport)
  
    # Test for IPv6
    if (hostwithport.count(':') > 2)
      if (hostwithport.count('.') == 1)
        thisport = hostwithport.split('.')[1].to_s
        thishost = hostwithport.split('.')[0].to_s
      else 
        thishost = hostwithport
        thisport = "none"
      end
    else
      # IPv4
      if (hostwithport.count('.') == 4)
        thisport = hostwithport.split('.')[-1,1].to_s
        thishost = hostwithport.split('.')
        thishost = thishost[0,thishost.length()-1].join('.')
      else 
        thishost = hostwithport
        thisport = "none"
      end
    end
    
    if thisport.include?(':')
      thisport = thisport.split(':')[0]
    end
    if thisport.include?(' ')
      thisport = thisport.split(' ')[0]
    end

    return [thishost, thisport]
  end
  
  def getport(thisport)
    if thisport == "none"
      return ""
    else
      return ":" + thisport.to_s
    end
  end
  
  def parse( line )
    if line.include?('(match)') and not line.include?('ICMPv6') and not line.include?('icmp6')
      proto = "TCP"
      _, ltime, host, rule, action, int, details, src, dst = /(.*)\s(.*)\spf:\s.*\srule\s(.*)\(match\)\:\s(.*)\s\w+\son\s(\w+)\:\s\((.*)\)\s(.*)\s>\s(.*)\:\s.*/.match(line).to_a
      
      # Assume the server is in the same time zone as the viewing client.
      timewithoffset = ltime.to_s + DateTime.now().zone()
      
      # Alternately, just set it this way to assume UTC/GMT
      #timewithoffset = ltime.to_s 
      
      hours,minutes,seconds,frac = Date.day_fraction_to_time(DateTime.now() - DateTime.parse(timewithoffset))
      
      # When connecting directly, there is no way to only view the end of the log. The clog program to view
      # circular logs will dump the entire log to the parser, then will tail it showing new messages.
      # Therefore, we can run a simple time check and only view entries from the last 5 minutes, or the
      # "future". On some systems, I have seen the clock show negative (-1hr 59mins) instead of 0, so we
      # can allow "future" messages just to be safe.
      if ((hours == 0) and (minutes < 5)) or (hours < 0)
        # Debug
        # printf("Adding entry from %s hours, %s minutes ago\n", hours.to_s, minutes.to_s)

        srchost, srcport = getipandport(src)

        dsthost, dstport = getipandport(dst)
        
        rule = rule.split('/')[0]
        
        if details.include?('flags ')
          _, flags = /.*\sflags\s\[(.*)\]/.match(details).to_a
          add_activity(:block => 'Flags',   :name => flags)
        end
        if details.include?('proto ')
          _, proto = /.*\sproto\s(.*)\s\(/.match(details).to_a
        elsif details.include?('proto: ')
          _, proto = /.*\sproto:\s(.*)\s\(/.match(details).to_a
        elsif details.include?('next-header ')
          _, proto = /.*\snext-header\s(.*)\s\(/.match(details).to_a
        end
  
      	add_activity(:block => 'action',  :name => action.to_s)
      	add_activity(:block => 'int',     :name => host.to_s + ":" + int.to_s)
      	add_activity(:block => 'rule',    :name => rule.to_s)
      	add_activity(:block => 'proto',   :name => proto.to_s)
      	add_activity(:block => 'srchost', :name => srchost.to_s)	
      	if srcport != "none"
      	  add_activity(:block => 'srcport', :name => srcport.to_s)
      	end
      	add_activity(:block => 'dsthost', :name => dsthost.to_s, :type => 5)	
      	if dstport != "none"
      	  add_activity(:block => 'dstport', :name => dstport.to_s, :type => 5)
      	end
      	add_activity(:block => 'srcdst',  :name => srchost.to_s + getport(srcport) + " > " + dsthost.to_s + getport(dstport) + " (" + proto.to_s + ")")
      else
        # Debug
        # printf("Not adding entry from %s hours, %s minutes ago\n", hours.to_s, minutes.to_s)
      end
    end
  end
end
