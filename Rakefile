require 'rake/gempackagetask'
spec = Gem::Specification.new do |s|
  s.name = "tracker"
  s.summary = "Client for tracktheprojects.com"
  s.description= File.read(File.join(File.dirname(__FILE__), 'README.md'))
  s.requirements =
    [ 'Internets' ]
  s.version = "0.0.1"
  s.author = "Anatoliy Chakkaev"
  s.email = "anatoliy.chakkaev@gmail.com"
  s.homepage = "http://tracker.tracktheprojects.com"
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.files = Dir['**/**']
  s.executables = [ 'tracker' ]
  #s.test_files = Dir["test/test*.rb"]
  s.has_rdoc = false
end
Rake::GemPackageTask.new(spec).define
