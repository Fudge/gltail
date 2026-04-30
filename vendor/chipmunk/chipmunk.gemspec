Gem::Specification.new do |s|
  s.name        = 'chipmunk'
  s.version     = '5.3.4.5'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Scott Lembcke', 'Beoran', 'John Mair (banisterfiend)']
  s.email       = ['beoran@rubyforge.org']
  s.summary     = 'Enhanced ruby bindings for the chipmunk 5.3.4 game physics engine.'
  s.description = 'Vendored, patched-for-Ruby-3+ chipmunk 5.3.4 bindings used by gltail.'
  s.homepage    = 'https://github.com/beoran/chipmunk'
  s.licenses    = ['MIT']

  s.files       = Dir['lib/**/*', 'ext/**/*', 'README', 'LICENSE', 'Rakefile']
  s.extensions  = ['ext/chipmunk/extconf.rb']
  s.require_paths = ['lib']
end
