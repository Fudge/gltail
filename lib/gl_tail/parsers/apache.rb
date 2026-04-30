# Apache combined-log parser.
#
# Adapter: fluentd's stock Apache2Parser handles the combined format.
# Mapper: HttpAccess with apache-flavored knobs (parsed user-agents, referrers
# stripped of http://, users get check_rate: 8, 4xx/5xx warnings).
class ApacheParser < Parser
  use_adapter [:fluentd, :apache2]
  use_mapper  [:http_access, {
    parse_useragent: true,
    users_check_rate: 8,
    strip_referer_http_prefix: true,
    warnings_for_4xx: true,
    skip_nil_useragent: true,
    events: %i[logins sales signups],
  }]
end
