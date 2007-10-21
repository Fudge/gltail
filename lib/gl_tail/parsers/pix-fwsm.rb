# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles logs from Cisco PIX or FWSM firewalls
# should also handle ASA logs, with minimal change...
# Leif Sawyer (leif@denali.net)
#

class PixParser < Parser
  def parse( line )
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

#    elsif line.include?(': Deny')
        # Deny udp src outside:_SRC_IP_/_SRC_PORT_ dst inside:_DST_IP_/_DST_PORT_ by access-group "_ACL_NAME"
#       printf("ACL denied access ...\n") if $VRB > 0

#    elsif line.include?('static translation')
        # Teardown static translation from inside:_SRC_IP_ to dmz-anc-csa:_DST_IP_ duration 0:01:00
#       printf("static translation ...\n") if $VRB > 0

    end
 end
end
