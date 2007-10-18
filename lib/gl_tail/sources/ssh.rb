

module GlTail
  module Source

    class SSH < Base
      config_attribute :command, "The Command to run"
      config_attribute :files, "The files to tail", :deprecated => "Should be embedded in the :command"
      config_attribute :host, "The Host to connect to"
      config_attribute :command, "The Command to run"
      config_attribute :user, "Username"
      config_attribute :port, "Port"
      config_attribute :keys, "Path to the ssh private key to use"
      config_attribute :password, "Password"

      def init
        
        @channels = []
        
        puts "Connecting to #{host}..."

        session_options = { }
        session_options[:port] = port if port
        session_options[:keys] = keys if keys
        session_options[:verbose] = :debug if $DBG > 1
        
        begin
          if password
            session_options[:auth_methods] = [ "password","keyboard-interactive" ]
            
            @session = Net::SSH.start(host, user, password, session_options)
          else
            @session = Net::SSH.start(host, user, session_options)
          end
        rescue SocketError => e
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

        @session.connection.process
      end
      
      def process
        @session.connection.process(true)
      end
      
      def update
        @channels.each { |ch| ch.connection.ping! }
      end

      def parse_line(data)
        @buffer.gsub(/\r\n/,"\n").gsub(/\n/, "\n\n").each("") do |line|

          unless line.include? "\n\n"
            @buffer = "#{line}"
            next
          end

          line.gsub!(/\n\n/, "\n")
          line.gsub!(/\n\n/, "\n")

          puts "#{host}[#{user}]: #{line}" if $DBG > 0

          parser.parse(line)
        end
        
        @buffer = "" if @buffer.include? "\n"
      end

      def do_tail( file, command )
        @session.open_channel do |channel|
          puts "Channel opened on #{@session.host}...\n"

          @buffer = ""
          channel.request_pty :want_reply => true

          channel.on_data do |ch, data|
            @buffer << data
            parse_line(data)
          end

          channel.on_success do |ch|
            channel.exec "#{command} #{file}  "
          end

          channel.on_failure do |ch|
            ch.close
          end

          channel.on_extended_data do |ch, data|
            puts "STDERR: #{data}\n"
          end

          channel.on_close do |ch|
            ch[:closed] = true
          end

          puts "Pushing #{host}\n"
          @channels.push(channel)
        end
      end
    end
  end
end
