require "bundler/gem_tasks"

#task :default => []

desc "Install gem in user dir"
task :bob do
	sh %{gem install --user-install pkg/jiraMule-#{Bundler::GemHelper.gemspec.version}.gem}
end

desc "Uninstall from user dir"
task :unbob do
	sh %{gem uninstall --user-install pkg/jiraMule-#{Bundler::GemHelper.gemspec.version}.gem}
end

task :echo do
	puts "= #{Bundler::GemHelper.gemspec.version} ="
end

task :run do
	sh %{ruby -Ilib bin/jm }
end

#  vim: set sw=4 ts=4 :
