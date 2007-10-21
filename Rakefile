# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/gl_tail.rb'

Hoe.new('gl_tail', GlTail::VERSION) do |p|
  p.rubyforge_name = 'gl_tail'
  p.author = 'Erlend Simonsen'
  p.email = 'mr@fudgie.org'
  p.summary = 'View real-time data and statistics from any logfile on any server with SSH, in an intuitive and entertaining way.'
  p.description = p.paragraphs_of('README.txt', 2..5).join("\n\n")
  p.url = p.paragraphs_of('README.txt', 0).first.split(/\n/)[1..-1]
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['ruby-opengl', '>= 0.40.1']
  p.extra_deps << ['net-ssh', '>= 1.1.2']
end

# vim: syntax=Ruby
