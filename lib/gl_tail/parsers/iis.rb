# IIS W3C extended-log parser.
#
# IIS doesn't have a stock fluentd parser, so we drive fluentd's generic
# RegexpParser with a named-capture pattern. The captures map directly onto
# the canonical HttpAccess record (host, method, path, code, size, referer,
# agent), avoiding the need for a custom adapter.
class IISParser < Parser
  REGEX = '/^(?<date>[\d-]+) (?<time>[\d:]+) (?<serverip>[\d.]+) ' \
          '(?<method>\S+) (?<path>\S+) (?<referer>\S+) (?<port>\S+) ' \
          '(?<size>[\d.]+) (?<host>\S+) (?<agent>\S+) (?<code>\d+).*$/'

  use_adapter [:fluentd, :regexp, { expression: REGEX }]
  use_mapper  [:http_access, {
    parse_useragent: false,
    strip_referer_http_prefix: false,
    warnings_for_4xx: false,
    skip_nil_useragent: false,  # legacy IIS parser emitted user agents unconditionally
    events: %i[logins sales signups],
  }]
end
