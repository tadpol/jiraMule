require "bundler/gem_tasks"

task :default => [:test]

tagName = "v#{Bundler::GemHelper.gemspec.version}"
gemName = "jiraMule-#{Bundler::GemHelper.gemspec.version}.gem"
builtGem = "pkg/#{gemName}"

desc "Install gem in user dir"
task :bob do
    sh %{gem install --user-install #{builtGem}}
end

desc "Uninstall from user dir"
task :unbob do
    sh %{gem uninstall --user-install #{builtGem}}
end

task :echo do
    puts tagName
    puts gemName
    puts builtGem
end

task :gemit do
    sh %{git checkout #{tagName}}
    Rake::Task[:build].invoke
    Rake::Task['push:gem'].invoke
    sh %{git checkout develop}
end

namespace :release do
    desc "Open a release branch"
    task :open, [:version] do |t, args|
        sh %{git checkout master}
        sh %{git checkout -b release/v#{args[:version]}}
        sh %{sed -i -e "s/VERSION = .*/VERSION = 'v#{args[:version]}'.freeze/" lib/JiraMule/version.rb}
        sh %{git commit lib/JiraMule/version.rb}
    end

    desc "Close a release branch"
    task :close, [:version] do |t, args|
        sh %{git checkout develop && git merge release/v#{args[:version]}}
        sh %{git checkout master && git merge release/v#{args[:version]}}
        sh %{git tag "v#{args[:version]}" -m "Release v#{args[:version]}"}
        sh %{git branch -d release/v#{args[:version]}}
    end
end

namespace :push do
    desc 'Push gem up to RubyGems'
    task :gem do
        sh %{gem push #{builtGem}}
    end

    namespace :github do
        desc "Make a release in Github"
        task :makeRelease do
            # ENV['GITHUB_TOKEN'] set by CI.
            # ENV['GITHUB_USER'] set by CI.
            # ENV['GITHUB_REPO'] set by CI
            # Create Release
            sh %{github-release info --tag #{tagName}} do |ok, res|
                if not ok then
                    sh %{github-release release --tag #{tagName}}
                end
            end
        end

        desc 'Push gem up to Github Releases'
        task :gem => [:makeRelease, :build] do
            # ENV['GITHUB_TOKEN'] set by CI.
            # ENV['GITHUB_USER'] set by CI.
            # ENV['GITHUB_REPO'] set by CI
            # upload gem
            sh %{github-release upload --tag #{tagName} --name #{gemName} --file #{builtGem}}
        end
    end
end

task :run do
    sh %{ruby -Ilib bin/jm }
end

desc "Prints a cmd to test this in another directory"
task :testwith do
    pwd=Dir.pwd.sub(Dir.home, '~')
    puts "ruby -I#{pwd}/lib #{pwd}/bin/jm "
end

desc 'Run RSpec'
task :rspec do
    Dir.mkdir("report") unless File.directory?("report")
    sh %{rspec --format html --out report/index.html --format progress}
end
task :test => [:rspec]

#  vim: set sw=4 ts=4 :
