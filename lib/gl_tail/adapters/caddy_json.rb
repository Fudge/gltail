require 'json'
require 'gl_tail/adapter'

module GlTail
  module Adapters
    # Caddy v2 emits one nested JSON object per access-log line. This adapter
    # flattens that into the canonical HTTP-access record shape used by
    # Mappers::HttpAccess (matching fluentd's Apache/Nginx output keys), so
    # one HttpAccess mapper covers Caddy alongside Apache/Nginx/IIS.
    class CaddyJson < ::GlTail::Adapter
      register :caddy_json

      def parse(line)
        log = JSON.parse(line)
      rescue JSON::ParserError
        return
      else
        request = log['request'] or return
        headers = request['headers'] || {}

        host = request['client_ip'] || request['remote_ip']
        return unless host

        yield(
          'host'    => host,
          'user'    => '-',
          'method'  => request['method'] || 'GET',
          'path'    => request['uri']    || '/',
          'code'    => (log['status'] || 0).to_s,
          'size'    => (log['size']   || 0).to_i,
          'referer' => Array(headers['Referer']).first || '-',
          'agent'   => Array(headers['User-Agent']).first || '-',
          'vhost'   => request['host']
        )
      end
    end
  end
end
