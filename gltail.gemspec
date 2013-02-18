# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gl_tail/version'

Gem::Specification.new do |gem|
  gem.name          = "gltail"
  gem.version       = GlTail::VERSION
  gem.authors       = ["Erlend Simonsen"]
  gem.email         = ["mr@fudgie.org"]
  gem.description   = <<-EOF
    Live log file visualization with OpenGL graphics. Turns just about any
    logfile into lively, colourful bouncy balls.
  EOF
  gem.summary       = %q{View real-time data and statistics from any logfile on any server with SSH, in an intuitive and entertaining way.}
  gem.homepage      = "http://www.fudgie.org"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('opengl', '0.7.0.pre2')
  gem.add_dependency('net-ssh', '>= 1.1.4')
  gem.add_dependency('net-ssh-gateway')
  gem.add_dependency('chipmunk')
  gem.add_dependency('file-tail')
end

# vim: syntax=Ruby
