# Postfix MTA log parser.

module GlTail::Adapters
  class Postfix < ::GlTail::Adapter
    register :postfix

    CONNECT      = /: connect from ([^\[]+)\[(\d+.\d+.\d+.\d+)\]/.freeze
    SASL         = /, sasl_username=(.*)/.freeze
    REJECT       = /: reject: RCPT from ([^\[]+)\[(\d+.\d+.\d+.\d+)\]: (\d+) (\d.\d.\d) (.*) from=<([^>]+)> to=<([^>]+)> proto=(.*) helo=<([^>]+)>/.freeze
    RBL_RHSBL    = /Sender address \[([^>]+)\] blocked using (.*)\; (.*)\;/.freeze
    RBL_PLAIN    = /Client host \[(\d+.\d+.\d+.\d+)\] blocked using (.*)\; (.*)\;/.freeze
    GENERIC_REJ  = /<([^>]+)>\: (.*);/.freeze
    FROM_SIZE    = /: from=<([^>]+)>, size=(\d+)/.freeze
    TO_INCOMING  = /: to=<([^>]+)>, .*delay=([\d.]+).*status=([^ ]+)/.freeze
    TO_OUTGOING  = /: to=<([^>]+)>.*relay=([^\[,]+).*delay=([\d.]+).*status=([^ ]+)/.freeze
    SPAMD        = /: spamd: (\w+ \w+) \((\d+\.\d+)\/.*\) for (.*):.* in (\d+\.\d+) seconds, (\d+) bytes/.freeze
    CLAMD        = /clamd\[\d+\]: .*: (.*) FOUND/.freeze
    WARNING      = /: warning: (.*)/.freeze

    def parse(line)
      record = dispatch(line) or return
      yield record
    end

    private

    def dispatch(line)
      case
      when line.include?(': connect from')
        m = CONNECT.match(line) or return
        host = m[1] == 'unknown' ? m[2] : m[1]
        { 'kind' => :connect, 'host' => host }
      when line.include?(' sasl_username=')
        m = SASL.match(line) or return
        { 'kind' => :sasl, 'username' => m[1] }
      when line.include?('NOQUEUE: reject:')
        parse_reject(line)
      when line.include?(' from=<')
        m = FROM_SIZE.match(line) or return
        { 'kind' => :from, 'from' => m[1], 'size' => m[2].to_f }
      when line.include?(' to=<')
        if line.include?('relay=local')
          m = TO_INCOMING.match(line) or return
          { 'kind' => :to_local, 'to' => m[1], 'delay' => m[2].to_f, 'status' => m[3] }
        else
          m = TO_OUTGOING.match(line) or return
          { 'kind' => :to_remote, 'to' => m[1], 'relay' => m[2], 'delay' => m[3].to_f, 'status' => m[4] }
        end
      when line.include?('spamd:') && (line.include?('clean message') || line.include?('identified spam'))
        m = SPAMD.match(line) or return
        status = m[1].include?('clean') ? 'clean' : 'spam'
        { 'kind' => :spamd, 'status' => status, 'proctime' => m[4].to_f }
      when line.include?('clamd[')
        m = CLAMD.match(line) or return
        { 'kind' => :clamd, 'virus' => m[1] }
      when line.include?(': warning:')
        m = WARNING.match(line) or return
        { 'kind' => :warning, 'text' => m[1] }
      end
    end

    def parse_reject(line)
      { 'kind' => :reject, 'rejection' => parse_rejection_reason(line) }
    end

    def parse_rejection_reason(line)
      m = REJECT.match(line)
      reason = m && m[5]
      return { 'kind' => :unknown } unless reason

      if reason.include?(' blocked using ')
        if reason.include?('Sender address')
          rm = RBL_RHSBL.match(reason)
          { 'kind' => :rbl, 'rbltype' => 'rhsbl', 'rbl' => rm && rm[2] }
        else
          rm = RBL_PLAIN.match(reason)
          { 'kind' => :rbl, 'rbltype' => 'rbl',   'rbl' => rm && rm[2] }
        end
      else
        gm = GENERIC_REJ.match(reason)
        { 'kind' => :generic, 'reason' => gm && gm[2] }
      end
    end
  end
end

module GlTail::Mappers
  class Postfix < ::GlTail::Mapper
    register :postfix

    KNOWN_WARNINGS = {
      'malformed domain name'                  => 'Malformed Domain Name',
      'non-SMTP command'                       => 'Non-SMTP Command',
      'Non-recoverable failure in name resolution' => 'DNS Failure',
      'hostname nor servname provided'         => 'Host Verification Failure',
      'address not listed for hostname'        => 'Hostname Without Address',
      'Connection rate limit exceeded'         => 'Per-Host Connection Rate Exceeded',
      'Connection concurrency limit exceeded'  => 'Per-Host Connection concurrency Exceeded',
      'numeric domain name in resource data'   => 'Numeric Domain Name',
      'numeric hostname'                       => 'Numeric Host Name',
      'valid_hostname: empty hostname'         => 'Empty Hostname',
      'Illegal address syntax'                 => 'Illegal Address Syntax',
    }.freeze

    def emit(record)
      case record['kind']
      when :connect
        add_activity(block: 'smtp', name: record['host'], size: 0.03)
      when :sasl
        add_activity(block: 'logins', name: "#{record['username']}/sasl", size: 0.1)
      when :reject
        add_activity(block: 'status', name: 'rejected', size: 0.03)
        emit_rejection(record['rejection'])
      when :from
        add_activity(block: 'mail from', name: record['from'], size: record['size'] / 100000.0)
      when :to_local
        add_activity(block: 'mail to', name: record['to'], size: record['delay'] / 10.0,
                     type: 5, color: [1.0, 0.0, 1.0, 1.0])
        add_activity(block: 'status', name: 'received', size: record['delay'] / 10.0, type: 3)
      when :to_remote
        add_activity(block: 'mail from', name: record['to'],   size: record['delay'] / 10.0)
        add_activity(block: 'smtp',      name: record['relay'], size: record['delay'] / 10.0)
        add_activity(block: 'status',    name: record['status'], size: record['delay'] / 10.0, type: 3)
      when :spamd
        add_activity(block: 'status', name: record['status'], size: record['proctime'] / 10.0)
      when :clamd
        add_activity(block: 'status', name: 'virus', size: 0.03)
        add_activity(block: 'viruses', name: record['virus'], size: 0.03)
      when :warning
        text = shorten_warning(record['text'])
        add_activity(block: 'status', name: 'warning', size: 0.03)
        add_activity(block: 'warnings', name: text, size: 0.03)
      end
    end

    private

    def emit_rejection(rej)
      case rej['kind']
      when :rbl
        add_activity(block: 'rejections', name: "#{rej['rbltype']} #{rej['rbl']}", size: 0.03) if rej['rbl']
      when :generic
        add_activity(block: 'rejections', name: rej['reason'], size: 0.03) if rej['reason']
      end
    end

    def shorten_warning(text)
      KNOWN_WARNINGS.each { |needle, short| return short if text.include?(needle) }
      text
    end
  end
end

class PostfixParser < Parser
  use_adapter :postfix
  use_mapper  :postfix
end
