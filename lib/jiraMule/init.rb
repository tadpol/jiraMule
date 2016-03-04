require 'pathname'
require 'yaml'

command :logwork do |c|
  c.syntax = 'jira init'
  c.summary = 'Initialize a project'
  c.description = %{Initialize a project }
  c.example 'Initialize a project', %{jira init}

  c.action do |args, options|

      p=Pathname.new(Dir.home) + '.rpjProject'
      if not p.exist? then
        cfg = {
          :jira => {},
          :harvest => {}
        }

        puts "No personal project file found, creating."

        puts "Lets start with Jira credentials:"
        cfg[:jira][:url] = ask("URL to Jira: ").to_s
        cfg[:jira][:userpass] = ask("Jira account name: ").to_s
        pswd = ask("Jira password: ").to_s
        
        system("security add-internet-password -U -a '%s' -s '%s' -w '%s'" % [
            cfg[:jira][:userpass],
            cfg[:jira][:url],
            pswd
        ])
        pswd = nil

        puts "Now lets get Harvest credentials:"
        subd = ask("Harvest subdomain: ").to_s
        cfg[:harvest][:url] = "https://%s.harvestapp.com" % [subd]
        cfg[:harvest][:user] = ask("Harvest username: ").to_s
        pswd = ask("Harvest password: ").to_s

        system("security add-internet-password -U -a '%s' -s '%s' -w '%s'" % [
            cfg[:harvest][:user],
            cfg[:harvest][:url],
            pswd
        ])
        pswd = nil

        p.open('w') { |io| io << cfg.to_yaml }
      end

      # Check for .rpjProject in $HOME
      # Ask for: .jira.userpass, .jira.url, .harvest.[user,url]
      #
      # Look for a .git in parent directories; if found look for .rpjProject there.
      # Else use pwd.
      # Ask for .jira.project, .harvest.[project,task]
      a = []
      home = Pathname.new(Dir.home)
      Pathname.new(Dir.pwd).ascend{|i| 
        break if i == home
        a << i + '.git'
      }
      a.select!{|i| i.exist? }.map{|i| i.to_s}

      if a.empty? then
        p = Pathname.new(Dir.pwd) + '.rpjProject'
      else
        p = Pathname.new(a.first) + '.rpjProject'
      end
      if not p.exist? then
        cfg = {
          :jira => {},
          :harvest => {}
        }

        puts "No project specific file found, creating."
        cfg[:jira][:project] = ask("Jira project code: ").to_s
        cfg[:harvest][:project] = ask("Harvest project code: ").to_s
        cfg[:harvest][:task] = ask("Harvest task name: ").to_s

        p.open('w') { |io| io << cfg.to_yaml }
      end

  end
end

#  vim: set et sw=2 ts=2 :
