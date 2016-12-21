# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'jiraMule/version'

Gem::Specification.new do |s|
  s.name        = 'jiraMule'
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

  s.add_runtime_dependency('chronic_duration', '~> 0.10.6')
  s.add_runtime_dependency('commander', '~> 4.4.0')
  s.add_runtime_dependency('inifile', '~> 3.0')
  s.add_runtime_dependency('mime-types', '~> 1.25.1')
  s.add_runtime_dependency('mime-types-data', '~> 3.2016')
  s.add_runtime_dependency('multipart-post', '~> 2.0.0')
  s.add_runtime_dependency('mustache', '~> 1.0')
  s.add_runtime_dependency('terminal-table', '~> 1.4.5')
  s.add_runtime_dependency('vine', '~> 0.2')
  s.add_runtime_dependency('zip', '~> 2.0.0')

  s.add_development_dependency('bundler', '~> 1.12.0')
  s.add_development_dependency('rspec', '~> 3.2')
  s.add_development_dependency('rake')
end

