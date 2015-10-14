require "bundler/gem_tasks"

#task :default => []

desc "Install gem in user dir"
task :bob do
	sh %{gem install --user-install pkg/jira-#{Bundler::GemHelper.gemspec.version}.gem}
end

task :echo do
	puts "= #{Bundler::GemHelper.gemspec.version} ="
end

#  vim: set sw=4 ts=4 :
