#require "bundler/gem_tasks" # Don't want these for now.

#task :default => []

desc "Build the gem"
task :build do
	sh %{gem build jiraMule.gemspec}
end

task :bob do
	sh %{gem install --user-install jira-0.0.1.gem}
end


#  vim: set sw=4 ts=4 :
