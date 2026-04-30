#!/usr/bin/env ruby
# Golden-record harness used to verify parser refactors don't change behavior.
#
# Each parser is exercised against test/samples/<parser>.txt; the resulting
# sequence of add_activity/add_event calls is serialized to
# test/golden/<parser>.json. A refactor is correct iff `verify` produces an
# empty diff against the captured goldens.
#
# Usage:
#   ruby test/golden_check.rb capture [parser ...]   # (re)write goldens
#   ruby test/golden_check.rb verify  [parser ...]   # diff against goldens, exit nonzero on mismatch
#   ruby test/golden_check.rb show    <parser>       # pretty-print the captured calls

require 'json'

# Globals normally set by bin/gl_tail. Several legacy parsers reference
# `$VRB` / `$DBG` directly (e.g. `printf(...) if $VRB > 0`); without these
# they raise NoMethodError on nil.
$DBG = 0
$VRB = 0

require_relative '../lib/gl_tail'

ROOT       = File.expand_path('..', __dir__)
SAMPLE_DIR = File.join(ROOT, 'test', 'samples')
GOLDEN_DIR = File.join(ROOT, 'test', 'golden')

# A stand-in for GlTail::Source that captures every method the parsers care
# about. It records add_activity / add_event opts in the order they arrive
# and exposes the same attributes (name, host, etc.) the parsers read.
class FakeSource
  attr_reader :calls

  def initialize(name: 'sample', host: 'sample.example.com')
    @name = name
    @host = host
    @calls = []
  end

  def name; @name; end
  def host; @host; end

  def add_activity(opts)
    @calls << ['add_activity', stringify(opts)]
  end

  def add_event(opts)
    @calls << ['add_event', stringify(opts)]
  end

  private

  def stringify(opts)
    opts.transform_keys(&:to_s)
  end
end

def parser_for(name)
  klass = Parser.registry[name.to_sym] or
    raise "no parser registered as :#{name} — known: #{Parser.registry.keys.sort.inspect}"
  source = FakeSource.new(name: 'sample', host: 'sample.example.com')
  [klass.new(source), source]
end

def run_samples(parser_name)
  sample_path = File.join(SAMPLE_DIR, "#{parser_name}.txt")
  unless File.exist?(sample_path)
    warn "no sample file: #{sample_path}"
    return nil
  end
  parser, source = parser_for(parser_name)
  records = []
  File.foreach(sample_path) do |line|
    line = line.chomp
    next if line.empty? || line.start_with?('#')
    before = source.calls.length
    record = { 'line' => line }
    begin
      parser.parse(line)
    rescue => e
      record['error'] = "#{e.class}: #{e.message}"
    end
    record['calls'] = source.calls[before..]
    records << record
  end
  records
end

def golden_path(parser_name)
  File.join(GOLDEN_DIR, "#{parser_name}.json")
end

def parsers_to_run(argv)
  if argv.empty?
    Dir.glob(File.join(SAMPLE_DIR, '*.txt')).map { |f| File.basename(f, '.txt') }.sort
  else
    argv
  end
end

def serialize(records)
  JSON.pretty_generate(records) + "\n"
end

mode = ARGV.shift or abort "usage: #{$0} capture|verify|show [parser ...]"

case mode
when 'capture'
  parsers_to_run(ARGV).each do |name|
    records = run_samples(name) or next
    File.write(golden_path(name), serialize(records))
    puts "captured: #{name} (#{records.size} lines)"
  end
when 'verify'
  failed = []
  parsers_to_run(ARGV).each do |name|
    records = run_samples(name) or next
    actual = serialize(records)
    expected = File.read(golden_path(name)) rescue (failed << [name, '(no golden — run capture first)']; next)
    if actual == expected
      puts "ok: #{name}"
    else
      failed << [name, 'records differ from golden']
    end
  end
  if failed.empty?
    puts "all goldens match"
  else
    failed.each { |name, msg| warn "FAIL: #{name}: #{msg}" }
    warn "to inspect: diff <(ruby #{$0} show #{failed[0][0]}) #{golden_path(failed[0][0])}"
    exit 1
  end
when 'show'
  name = ARGV.shift or abort "usage: #{$0} show <parser>"
  records = run_samples(name)
  puts serialize(records)
else
  abort "unknown mode: #{mode}"
end
