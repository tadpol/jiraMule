require "bundler/gem_tasks"

desc "Run specs"
# what does this do?
task :spec do
  sh "bundle exec rspec -f progress"
end

#task :default => [:build]

desc "Build the gem"
task :build do
	sh %{gem build jiraMule.gemspec}
end

task :install do
	sh %{gem install --user-install jira-0.0.1.gem}
end
