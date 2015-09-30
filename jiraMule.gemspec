# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'jiraMule/version'

Gem::Specification.new do |s|
  s.name        = 'jira'
  s.version     = JiraMule::VERSION
  s.authors     = ['Michael Conrad Tadpol Tilstra']
  s.email       = ['tadpol@tadpol.org']
  s.license     = 'MIT'
  s.homepage    = ''
  s.summary     = 'A collection of things that I do with jira'
  s.description = %{A collection of things that I do with jira.

Many of which are either big batch operations, or need bits of info from
the command line.  All of which turn out to be better handled as a command
line app.

This very specifically does not try to be a generic jira tool; those exist
already.  Rather this is specific to things I need.
}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency('commander', '~> 4.3.4')

  s.add_development_dependency('bundler', '~> 1.7.6')
  s.add_development_dependency('rspec', '~> 3.2')
  s.add_development_dependency('rake')
end

