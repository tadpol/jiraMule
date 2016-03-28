require 'pathname'
require 'yaml'

command :init do |c|
  c.syntax = 'jm init'
  c.summary = 'Initialize a project'
  c.description = %{Initialize a project }
  c.example 'Initialize a project', %{jm init}

  c.action do |args, options|

      p=Pathname.new(Dir.home) + '.rpjProject'
      if not p.exist? then
        cfg = {
          'jira' => {},
          'harvest' => {}
        }

        puts "No personal project file found, creating."

        puts "Lets start with Jira credentials:"
        cfg['jira']['url'] = ask("URL to Jira: ").to_s
        cfg['jira']['uesrpass'] = ask("Jira account name: ").to_s
        pswd = ask("Jira password: ").to_s
        
        system("security add-internet-password -U -a '%s' -s '%s' -w '%s'" % [
            cfg['jira']['uesrpass'],
            cfg['jira']['url'],
            pswd
        ])
        pswd = nil

        puts "Now lets get Harvest credentials:"
        subd = ask("Harvest subdomain: ").to_s
        cfg['harvest']['url'] = "https://%s.harvestapp.com" % [subd]
        cfg['harvest']['uesr'] = ask("Harvest username: ").to_s
        pswd = ask("Harvest password: ").to_s

        system("security add-internet-password -U -a '%s' -s '%s' -w '%s'" % [
            cfg['harvest']['uesr'],
            cfg['harvest']['url'],
            pswd
        ])
        pswd = nil

        p.open('w') { |io| io << cfg.to_yaml }
        puts "Created #{p.to_s}"
      end

      p = Pathname.new(Dir.pwd) + '.rpjProject'
      if not p.exist? then
        cfg = {
          'jira' => {},
          'harvest' => {}
        }

        puts "No project specific file found, creating."
        cfg['jira']['project'] = ask("Jira project code: ").to_s
        cfg['harvest']['project'] = ask("Harvest project code: ").to_s
        cfg['harvest']['task'] = ask("Harvest task name: ").to_s

        p.open('w') { |io| io << cfg.to_yaml }
        puts "Created #{p.to_s}"
      end

  end
end

#  vim: set et sw=2 ts=2 :
