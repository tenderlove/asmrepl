$: << File.expand_path("lib")

require "asmrepl/version"

Gem::Specification.new do |s|
  s.name        = "asmrepl"
  s.version     = ASMREPL::VERSION
  s.summary     = "Write assembly in a REPL!"
  s.description = "Tired of writing assembly and them assembling it? Now you can write assembly and evaluate it!"
  s.authors     = ["Aaron Patterson"]
  s.email       = "tenderlove@ruby-lang.org"
  s.files       = `git ls-files -z`.split("\x0")
  s.test_files  = s.files.grep(%r{^test/})
  s.homepage    = "https://github.com/tenderlove/asmrepl"
  s.license     = "Apache-2.0"
  s.bindir      = "bin"

  s.executables << "asmrepl"

  s.add_development_dependency 'minitest', '~> 5.14'
  s.add_development_dependency 'crabstone', '~> 4.0'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_dependency 'fisk', '~> 2.3.1'
end
