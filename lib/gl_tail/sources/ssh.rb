require 'net/ssh/gateway'

module GlTail
  module Source

    class SSH < Base
      config_attribute :source, "The type of Source"
      config_attribute :command, "The Command to run"
      config_attribute :files, "The files to tail", :deprecated => "Should be embedded in the :command"
      config_attribute :host, "The Host to connect to"
      config_attribute :command, "The Command to run"
      config_attribute :user, "Username"
      config_attribute :port, "Port"
      config_attribute :keys, "Path to the ssh private key to use"
      config_attribute :password, "Password"
      config_attribute :gateway, "Gateway"

      def init

        @channels = []

        session_options = { }
        session_options[:port] = port if port
        session_options[:keys] = keys if keys
        session_options[:verbose] = :debug if $DBG > 1
        session_options[:password] = password if password

        begin
          if gateway
            puts "Connecting via gateway #{gateway}..." if($VRB > 0 || $DBG > 0)
            gw = Net::SSH::Gateway.new(gateway, user, session_options)
            puts "Connecting to #{host}..." if($VRB > 0 || $DBG > 0)
            @session = gw.ssh(host, user, session_options)
          else
            puts "Connecting to #{host}..." if($VRB > 0 || $DBG > 0)
            @session = Net::SSH.start(host, user, session_options)
          end
        rescue SocketError, Errno::ECONNREFUSED => e
          puts "!!! Could not connect to #{host}. Check to make sure that this is the correct url."
          puts $! if $DBG > 0
          exit
        rescue Net::SSH::AuthenticationFailed => e
          puts "!!! Could not authenticate on #{host}. Make sure you have set the username and password correctly. Or if you are using SSH keys make sure you have not set a password."
          puts $! if $DBG > 0
          exit
        end

        # FIXME: add support for multiple files (eg. write files accessor)
        do_tail(files, command)

        @session.process(0)
      end

      def process
        @session.process(0)
      end

      def update
        @channels.each { |ch| ch.process }
      end

      def parse_line(data)
        @buffer.split("\n").each() do |line|

#          unless line.include? "\n"
#            @buffer = "#{line}"
#            next
#          end

#          line.gsub!(/\n\n/, "\n")
#          line.gsub!(/\n\n/, "\n")

          puts "#{host}[#{user}]: #{line}" if $DBG > 0

          parser.parse(line)
        end

        @buffer = "" if @buffer.include? "\n"
      end

      def do_tail( file, command )
        @session.open_channel do |channel|
          puts "Channel opened on #{@session.host}...\n" if($VRB > 0 || $DBG > 0)

          @buffer = ""
#          channel.request_pty :want_reply => true

          channel.on_data do |ch, data|
            @buffer << data
            parse_line(data)
          end

          channel.on_open_failed do |ch|
            ch.close
          end

          channel.on_extended_data do |ch, data|
            puts "STDERR: #{data}\n"
          end

          channel.on_close do |ch|
            ch[:closed] = true
          end

          channel.exec "#{command} #{file}  "

          puts "Pushing #{host}\n" if($VRB > 0 || $DBG > 0)
          @channels.push(channel)
        end
      end
    end
  end
end
