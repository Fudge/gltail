# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gl_tail/version'

Gem::Specification.new do |gem|
  gem.name          = 'gltail'
  gem.version       = GlTail::VERSION
  gem.authors       = ['Erlend Simonsen']
  gem.email         = ['mr@fudgie.org']
  gem.description   = <<-EOF
    Live log file visualization with OpenGL graphics. Turns just about any
    logfile into lively, colourful bouncy balls.
  EOF
  gem.summary       = %q{View real-time data and statistics from any logfile on any server with SSH, in an intuitive and entertaining way.}
  gem.homepage      = 'http://www.fudgie.org'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency('opengl', '~> 0.10')
  gem.add_dependency('glu', '~> 8.3')
  gem.add_dependency('glut', '~> 8.3')
  gem.add_dependency('net-ssh', '>= 2.9')
  gem.add_dependency('net-ssh-gateway')
  gem.add_dependency('chipmunk', '~> 5.3.4.5')
  gem.add_dependency('file-tail')

  # No longer in stdlib as of Ruby 3.5+; net-ssh requires it.
  gem.add_dependency('logger')
  # Removed from default gems in Ruby 3.4+; gl_tail/resolver.rb requires it.
  gem.add_dependency('resolv-replace')
  # Required by net-ssh to read ed25519 keys (now the openssh default).
  gem.add_dependency('ed25519', '~> 1.2')
  gem.add_dependency('bcrypt_pbkdf', '~> 1.0')
end

# vim: syntax=Ruby
