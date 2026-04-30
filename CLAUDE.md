# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

glTail is a Ruby program that tails log files (typically over SSH from remote servers) and visualizes incoming log events as bouncing colored blobs in an OpenGL window. The author's own README warns the code is messy and uses global variables — treat existing style as legacy and avoid large refactors.

## Commands

- First-time setup: `bundle install && bin/setup` — `bin/setup` builds the vendored chipmunk C extension; bundler does *not* auto-build extensions for `path:` gems, so this step is mandatory and must be re-run if the chipmunk source changes.
- Run: `bundle exec ruby bin/gl_tail <configfile>` (defaults to `gl_tail.yaml` in the cwd; always run via `bundle exec` so the vendored chipmunk and the right opengl/glu/glut are loaded).
- Generate a starter config: `bin/gl_tail --new myconfig.yaml` (copies `dist/config.yaml`).
- List built-in parsers: `bin/gl_tail <any-config> --parsers`.
- List configuration options: `bin/gl_tail <any-config> --options`.
- Debug: `--debug`/`-d` (general), `--debug-ssh`/`-ds` (SSH only), `--quiet`/`-q`.
- Build gem: `rake build` (Rakefile only loads `bundler/gem_tasks` — `build`, `install`, `release`).

Note: most flags other than `--new`, `--help`, and `--version` require a config-file argument because `bin/gl_tail` validates the file's existence before dispatching. That's pre-existing behavior, not a bug.

There is no real test suite — `test/test_gl_tail.rb` is empty.

Runtime keys while the visualizer is running: `f` toggles target FPS, `b` cycles default blob type, `space` toggles bouncing, `shift+f` toggles fullscreen. `SIGUSR2` toggles debug level.

## Runtime dependencies & modernization notes

The codebase was last touched against Ruby 2.1 (`.versions.conf` still says `ruby-2.1.4`); it now runs on Ruby 3.x+ but only after a small set of compatibility patches:

- **chipmunk 5.3.4.5** is vendored under `vendor/chipmunk/` and patched for Ruby 3.x's stricter `rb_funcall` argc check (`rb_cpSpace.c` lines ~141 and ~449). The upstream gem on rubygems.org will not compile against Ruby 3+. Bundler picks the vendored copy via the `gem 'chipmunk', path: 'vendor/chipmunk'` line at the top of `Gemfile`.
- **opengl/glu/glut 0.10/8.x** are split gems now (the old `opengl` gem bundled all three). All three need GCC 14+ warning-to-error demotions to build; that's wired into `.bundle/config` via `bundle config set build.<gem> --with-cflags=...` (see `.bundle/config`). If you bundle on a fresh checkout, run `bin/setup` after `bundle install` to (re)build the vendored chipmunk too.
- **logger** and **resolv-replace** were dropped from Ruby's default gems in 3.4/3.5; both are now declared in `gltail.gemspec`.
- `bin/gl_tail` had `trap('KILL')` (illegal — SIGKILL is untrappable) and a `require <relative path>` (broken since Ruby 1.9 but somehow tolerated). Both fixed.
- `vendor/chipmunk/lib/chipmunk.rb` previously referenced the long-removed `Config::CONFIG` constant; it now uses `RbConfig::CONFIG`.

System libraries required: GL, GLU, freeglut, plus a working display (X or XWayland). SSH key auth or in-config passwords are needed for remote sources.

## Architecture

Entry point `bin/gl_tail` parses CLI args, loads `lib/gl_tail.rb` (which requires every subsystem), then:

1. `GlTail::Config.parse_yaml(file)` — `lib/gl_tail/config/yaml_parser.rb` reads the YAML, building a `Config` (`lib/gl_tail/config.rb`) of servers, parsers, groups, and screen settings via the `Configurable` mixin (`lib/gl_tail/config/configurable.rb`).
2. `GlTail::Engine.new(config).start` — `lib/gl_tail/engine.rb` is the main loop. It owns the GLUT window, a Chipmunk physics `space`, the FontStore/BlobStore caches, and orchestrates per-frame rendering of activities/blocks/items.

Data flow per server:

- **Sources** (`lib/gl_tail/sources/`) produce log lines. `base.rb` is the abstract source; `ssh.rb` tails remote files via Net::SSH (optionally through a gateway); `local.rb` tails local files via `file/tail`. Each source is associated with one or more parsers.
- **Parsers** (`lib/gl_tail/parsers/*.rb`) subclass `Parser` (`lib/gl_tail/parser.rb`). The base class auto-registers subclasses by stripping `Parser` from the class name and downcasing — so `class ApacheParser < Parser` registers as `:apache`. New-style parsers compose two collaborators (see "Parser pipeline" below); legacy parsers still override `#parse(line)` directly. `lib/gl_tail.rb` globs `parsers/*.rb` so dropping a new file in that dir auto-loads it.
- **Activities / Blocks / Items / Elements** (`activity.rb`, `block.rb`, `item.rb`, `element.rb`) are the visualization primitives parsers emit. The Engine consumes them each frame, runs Chipmunk physics (`$PHYSICS = true`), and renders blobs/text via `BlobStore` and `FontStore` (the latter loads `lib/gl_tail/font.bin`).
- **Resolver** (`resolver.rb`) does async DNS lookups for IPs surfaced by parsers.

### Parser pipeline (Adapter + Mapper)

Originally each parser conflated regex/JSON parsing with the gltail-domain
logic of `add_activity` / `add_event` calls. Newer parsers split those:

- **Adapter** (`lib/gl_tail/adapter.rb`, `lib/gl_tail/adapters/*.rb`): `parse(line) { |record| ... }`. Turns a raw line into one or more normalized record hashes. Implementations: `Adapters::Fluentd` wraps any `Fluent::Plugin::*Parser` (apache2, nginx, json, regexp, syslog, …); `Adapters::CaddyJson` flattens Caddy v2's nested JSON into the canonical HTTP-access shape; `Adapters::Regex` is a simple named-capture regex for legacy formats fluentd doesn't cover.
- **Mapper** (`lib/gl_tail/mapper.rb`, `lib/gl_tail/mappers/*.rb`): `emit(record)`. Turns a normalized record into `add_activity` / `add_event` calls. `Mappers::HttpAccess` covers Apache, Nginx, IIS, and Caddy via a single mapper plus per-parser config flags (parsed user-agents, referrer normalization, content-type extension lists, which events to emit). The historical per-parser quirks are intentionally preserved as flags so byte-compat with the old behavior is auditable via `test/golden/`.

A new-style parser is a 5-line shell:

```ruby
class ApacheParser < Parser
  use_adapter [:fluentd, :apache2]
  use_mapper  [:http_access, { parse_useragent: true, users_check_rate: 8, ... }]
end
```

The base `Parser#parse` pairs `adapter.parse(line) { |record| mapper.emit(record) }`. Every shipped parser has been converted; legacy parsers that need to live alongside (custom in-tree subclasses) can still override `#parse` directly — the base class falls back to the override when no `use_adapter`/`use_mapper` is declared.

Each `lib/gl_tail/parsers/<name>.rb` defines all three collaborators inline (a parser-specific Adapter under `GlTail::Adapters::<Name>`, a Mapper under `GlTail::Mappers::<Name>`, and the Parser shell), so per-format logic stays colocated. Shared mappers (just `HttpAccess` today, covering Apache/Nginx/IIS/Caddy) live in `lib/gl_tail/mappers/`. The HTTP cluster uses fluentd's stock parsers; everything else uses bespoke per-parser adapters because their log shapes are unique.

Adding a new HTTP-access log format: write an Adapter that yields the canonical record shape (`host`, `method`, `path`, `code`, `size`, `referer`, `agent`), and a Parser file wiring it to `Mappers::HttpAccess` with the appropriate flags.

### Other behavior breaks worth noting

- **`pfsense` had two latent bugs that left it unusable on Ruby 3.0+**: a `sourechost` typo (NameError on every match) and a call to the long-removed `Date.day_fraction_to_time`. Both are fixed in the new `Parsers::PFSense`, and the 5-minute clog-replay time filter is now opt-in (`recent_only: true`). The old parser produced zero output on modern Ruby; the new one actually works.

### Behavior break in nginx

The legacy `NginxParser` regex captured status *before* the request string
(`[date] STATUS "request"`), which only matches a custom `log_format`
somebody had configured upstream. The new `Parsers::Nginx` uses fluentd's
stock `NginxParser`, which expects the standard combined format
(`[date] "request" status`). If a user had been pointing gltail at a server
running the old custom format they will now see zero activities — a config
break, not a code break, but worth knowing.

### Test harness

`test/golden_check.rb` is a tiny golden-record harness: given `test/samples/<parser>.txt`, it runs lines through `Parser.parse` against a stub source, captures the sequence of `add_activity` / `add_event` calls, and snapshots them as JSON in `test/golden/<parser>.json`. Use it before any parser refactor:

```sh
bundle exec ruby test/golden_check.rb capture <parser>   # record golden
bundle exec ruby test/golden_check.rb verify  <parser>   # diff against golden
bundle exec ruby test/golden_check.rb show    <parser>   # print captured calls
```

All 19 shipped parsers have committed goldens (`test/samples/<name>.txt` + `test/golden/<name>.json`); the harness gates every parser conversion. The harness sets `$VRB = $DBG = 0` so legacy parsers' `printf(...) if $VRB > 0` branches don't NoMethodError out of test scope.

## Config files

`config.yaml` (top-level) is a working example. `dist/config.yaml` is the template copied by `--new`. Both define `config:` (screen/window/physics), `servers:` (host + sources + parser), and `groups:` (visual grouping/coloring).
