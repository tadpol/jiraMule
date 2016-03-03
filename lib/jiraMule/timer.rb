#

command :time do |c|
  c.syntax = 'jira time [options] <key>'
  c.summary = 'Log work spent'
  c.description = %{Log time spent on a issue, sending update to both jira and harvest}
  c.option '-m', 'message to add to work log'
  c.option '--task', 'Which Harvest task to track against'
  c.option '--[no-]harvest', %{Don't post time to harvest}
  c.example 'Log some work done on an issue', %{jira time BUG-42 1h 12m}

  c.action do |args, options|
    options.defaults :harvest => true, :m => ''
    jira = JiraUtils.new(args, options)
    harvest = HarvestUtils.new(args, options)

    key = jira.expandKeys(args).first
    pid, tid = harvest.taskIDfromProjectAndName()
    printVars(:k=>key, :pt=>[pid,tid], :m=>options.m)

    jmsg = %{[#{pid['code']}] #{pid['name']} - #{tid['name']}: #{options.m}}
    hmsg =  %{#{key} #{options.m}}

    #jira.logWork(key, 20*60, jmsg)
    harvest.logWork(pid['id'], tid['id'], (2*3600), hmsg)

  end
end

#  vim: set et sw=2 ts=2 :
