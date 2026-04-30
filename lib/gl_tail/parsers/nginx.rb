# Nginx combined-log parser.
#
# Adapter: fluentd's NginxParser. (The previous gltail regex had status and
# request flipped — a long-standing bug; normalizing to standard format.)
# Mapper: HttpAccess with nginx-flavored knobs (no useragent parsing, no
# referrer-prefix stripping, no warnings, plus a Registration event the
# other HTTP parsers don't emit).
class NginxParser < Parser
  use_adapter [:fluentd, :nginx]
  use_mapper  [:http_access, {
    parse_useragent: false,
    strip_referer_http_prefix: false,
    warnings_for_4xx: false,
    skip_nil_useragent: true,
    events: %i[logins registration],
    login_substring: '/login',
  }]
end
