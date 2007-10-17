# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)

# Parser which handles Postfix logs
class PostfixParser < Parser
  def parse( line )
    if line.include?(': connect from')
      _, host, ip = /: connect from ([^\[]+)\[(\d+.\d+.\d+.\d+)\]/.match(line).to_a
      if host
        host = ip if host == 'unknown'
        add_activity(:block => 'smtp', :name => host, :size => 0.03)
      end
    elsif line.include?(' sasl_username=')
      _, username = /, sasl_username=(.*)/.match(line).to_a
      add_activity(:block => 'logins', :name => "#{username}/sasl", :size => 0.1)
    elsif line.include?('NOQUEUE: reject:')
      #
      # Parse rejection messages, including RBL rejections.
      #  The rejection status could be displayed with the actual error codes if desired.
      #   Change :name => 'rejected'
      #   To     :name => status
      #   Or     :name => extstatus
      #
      _, host, ip, status, extstatus, rejectreason, from, to, proto, helo = /: reject: RCPT from ([^\[]+)\[(\d+.\d+.\d+.\d+)\]: (\d+) (\d.\d.\d) (.*) from=<([^>]+)> to=<([^>]+)> proto=(.*) helo=<([^>]+)>/.match(line).to_a
      add_activity(:block => 'status', :name => 'rejected', :size => 0.03)
      host = ip if host == 'unknown'
      if not rejectreason.nil?
        if rejectreason.include?(' blocked using ')
          rbltype = 'rbl'
          if rejectreason.include?('Sender address')
            # RHSBL-stle rejection message
            _, ip, rbl, rbltext = /Sender address \[([^>]+)\] blocked using (.*)\; (.*)\;/.match(rejectreason).to_a
            rbltype = 'rhsbl'
          else
            # Plain RBL rejection message
            _, ip, rbl, rbltext = /Client host \[(\d+.\d+.\d+.\d+)\] blocked using (.*)\; (.*)\;/.match(rejectreason).to_a
          end
          if not rbl.nil?
            #            add_activity(:block => 'rejections', :name => host, :size => 0.03)
            add_activity(:block => 'rejections', :name => rbltype + ' ' + rbl, :size => 0.03)
          end
        else
          # Generic rejection message, print the whole thing.
          _, address, reason = /<([^>]+)>\: (.*);/.match(rejectreason).to_a
          #            add_activity(:block => 'rejections', :name => host, :size => 0.03)
          add_activity(:block => 'rejections', :name => reason, :size => 0.03)
        end
      end
    elsif line.include?(' from=<')
      _, from, size = /: from=<([^>]+)>, size=(\d+)/.match(line).to_a
      if from
        add_activity(:block => 'mail from', :name => from, :size => size.to_f/100000.0)
      end
    elsif line.include?(' to=<')
      if line.include?('relay=local')
        # Incoming
        _, to, delay, status = /: to=<([^>]+)>, .*delay=([\d.]+).*status=([^ ]+)/.match(line).to_a
        add_activity(:block => 'mail to', :name => to, :size => delay.to_f/10.0, :type => 5, :color => [1.0, 0.0, 1.0, 1.0])
        add_activity(:block => 'status', :name => 'received', :size => delay.to_f/10.0, :type => 3)
      else
        # Outgoing
        _, to, relay_host, delay, status = /: to=<([^>]+)>.*relay=([^\[,]+).*delay=([\d.]+).*status=([^ ]+)/.match(line).to_a
        add_activity(:block => 'mail from', :name => to, :size => delay.to_f/10.0)
        add_activity(:block => 'smtp', :name => relay_host, :size => delay.to_f/10.0)
        add_activity(:block => 'status', :name => status, :size => delay.to_f/10.0, :type => 3)
      end
    elsif line.include?('spamd:') and (line.include?('clean message') or line.include?('identified spam'))
      #
      # Parse spamd log entries for the result summary, and add the clean/spam status to the status block.
      #
      # NOTE/TODO: Much more could be done with this block, including averaging scores and processing times
      #
      _, status, score, mailaddr, proctime, size = /: spamd: (\w+ \w+) \((\d+\.\d+)\/.*\) for (.*):.* in (\d+\.\d+) seconds, (\d+) bytes/.match(line).to_a
      if not status.nil?
        status = status.include?('clean') ? 'clean' : 'spam'
        add_activity(:block => 'status', :name => status, :size => proctime.to_f/10.0)
      end
    elsif line.include?('clamd[')
      #
      # Parse clamd log entries. Print the name of the detected virus.
      #
      _, virusname = /clamd\[\d+\]: .*: (.*) FOUND/.match(line).to_a
      add_activity(:block => 'status', :name => 'virus', :size => 0.03)
      add_activity(:block => 'viruses', :name => virusname, :size => 0.03)
    elsif line.include?(': warning:')
      #
      # Parse warning messages. If it is a known warning, shorten the message, otherwise print the full text
      #
      _, warningtext = /: warning: (.*)/.match(line).to_a
      if warningtext.include?('malformed domain name')
        warningtext = 'Malformed Domain Name'
      elsif warningtext.include?('non-SMTP command')
        warningtext = 'Non-SMTP Command'
      elsif warningtext.include?('Non-recoverable failure in name resolution')
        warningtext = 'DNS Failure'
      elsif warningtext.include?('hostname nor servname provided')
        warningtext = 'Host Verification Failure'
      elsif warningtext.include?('address not listed for hostname')
        warningtext = 'Hostname Without Address'
      elsif warningtext.include?('Connection rate limit exceeded')
        warningtext = 'Per-Host Connection Rate Exceeded'
      elsif warningtext.include?('Connection concurrency limit exceeded')
        warningtext = 'Per-Host Connection concurrency Exceeded'
      elsif warningtext.include?('numeric domain name in resource data')
        warningtext = 'Numeric Domain Name'
      elsif warningtext.include?('numeric hostname')
        warningtext = 'Numeric Host Name'
      elsif warningtext.include?('valid_hostname: empty hostname')
        warningtext = 'Empty Hostname'
      elsif warningtext.include?('Illegal address syntax')
        warningtext = 'Illegal Address Syntax'
      end
      add_activity(:block => 'status', :name => 'warning', :size => 0.03)
      add_activity(:block => 'warnings', :name => warningtext, :size => 0.03)
    end
  end
end
