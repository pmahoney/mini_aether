Gem::Specification.new do |s|
  s.name = 'mini_aether'
  s.version = File.read(File.expand_path('../VERSION', __FILE__))
  s.platform = 'java'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README.md', 'COPYING']
  s.summary = 'wrapper around some parts of aether'
  s.description = 'Resolves Aether artifact dependencies, downloads, and requires them.'
  s.author = 'Patrick Mahoney'
  s.email = 'pat@polycrystal.org'
  s.homepage = 'https://github.com/pmahoney/mini_aether'
  s.files = Dir['lib/**/*.rb', 'lib/**/*.xml', 'test/**/*.rb', 'test/data/*.gemspec']

  s.add_development_dependency 'minitest'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'version'
end
