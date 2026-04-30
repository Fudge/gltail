# Caddy v2 JSON access-log parser.
#
# Adapter: CaddyJson — flattens Caddy's nested JSON record into the canonical
# HTTP-access shape so one mapper covers Caddy alongside Apache/Nginx/IIS.
# Mapper: HttpAccess with apache-flavored knobs.
class CaddyParser < Parser
  use_adapter :caddy_json
  use_mapper  [:http_access, {
    parse_useragent: true,
    users_check_rate: 8,
    strip_referer_http_prefix: true,
    warnings_for_4xx: true,
    skip_nil_useragent: true,
    events: %i[logins sales signups],
  }]
end
