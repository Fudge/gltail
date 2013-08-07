# cassandra.rb - OpenGL visualization of your server traffic
# Copyright 2013 Sven Delmas <sven@datastax.com>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles cassandra/system.log (standard log setup) from Apache Cassandra
class CassandraParser < Parser
  def parse( line )
    # main line parse
    _, priority, thread, date, time, fileName, lineNumber, message = /(\S+) \[(\S+)\] (\S+) (\S+) (\S+) \(line (\S+)\) (.*)/.match(line).to_a

    if message
      # We got a message, so let's parse it for interesting stuff
      _, cassandra_version = /Cassandra version: (\S+)/.match(message).to_a
      _, dse_version = /DSE version: (\S+)/.match(message).to_a
      _, dropped_messages = /(\S+) messages dropped in last/.match(message).to_a
      _, compacted = /Compacted (\S+) sstables to/.match(message).to_a
      _, load_endpoint, load = /Endpoint (\S+) state changed LOAD = (\S+)/.match(message).to_a
      _, schema_endpoint, schema = /Endpoint (\S+) state changed SCHEMA = (\S+)/.match(message).to_a
      _, flushing = /Completed flushing (\S+)/.match(message).to_a

      if dropped_messages
        add_activity(:block => 'dropped messages', :name => server.name)
      end
      if compacted
        add_activity(:block => 'compaction done', :name => server.name)
      end
      if flushing
        add_activity(:block => 'flushing', :name => server.name)
      end

      # Events to pop up
      if cassandra_version
        server_name = server.name + '=' + cassandra_version
        server_message = server.name + ' started version: ' + cassandra_version
        add_event(:block => 'cassandra servers', :name => server_name, :message => server_message, :update_stats => true, :color => [0.0, 1.0, 0.0, 0.0])
      end
      if dse_version
        server_name = server.name + '=' + dse_version
        server_message = server.name + ' started version: ' + dse_version
        add_event(:block => 'dse servers', :name => server_name, :message => server_message, :update_stats => true, :color => [0.0, 1.0, 0.0, 0.0])
      end
      if schema_endpoint
        schema_name = schema_endpoint
        schema_message = schema_endpoint + ' changed schema: ' + schema
        add_activity(:block => 'schemas', :name => schema_name)
      end
      add_event(:block => 'errors', :name => server.name, :message => message, :update_stats => true, :color => [1.0, 0.0, 0.0, 0.0]) if priority == "ERROR"
      add_event(:block => 'warnings', :name => server.name, :message => message, :update_stats => true, :color => [1.0, 1.0, 0.0, 0.0]) if priority == "WARN"
    end
  end
end
