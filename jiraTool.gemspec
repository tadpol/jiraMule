# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'jiraTool/version'

Gem::Specification.new do |s|
  s.name        = 'jira'
  s.version     = JiraTool::VERSION
  s.authors     = ['Michael Conrad Tadpol Tilstra']
  s.email       = ['tadpol@tadpol.org']
  s.license     = 'MIT'
  s.homepage    = ''
  s.summary     = ''
  s.description = ''

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency('commander', '~> 4.3.4')

  s.add_development_dependency('bundler', '~> 1.10')
  s.add_development_dependency('rspec', '~> 3.2')
  s.add_development_dependency('rake')
end

