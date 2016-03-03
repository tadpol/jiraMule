#
require 'chronic_duration'

command :logwork do |c|
  c.syntax = 'jira logwork [options] <key> <time spent...>'
  c.summary = 'Log work spent'
  c.description = %{Log time spent on a issue, sending update to both jira and harvest}
  c.option '-m', 'message to add to work log'
  c.option '--task', 'Which Harvest task to track against'
  #c.option '--[no-]harvest', %{Don't post time to harvest}
  c.example 'Log some work done on an issue', %{jira time BUG-42 1h 12m}

  c.action do |args, options|
    options.defaults :harvest => true, :m => ''
    jira = JiraUtils.new(args, options)
    harvest = HarvestUtils.new(args, options)

    key = jira.expandKeys(args).shift
    ts = ChronicDuration.parse(args.join(' '))
    pid, tid = harvest.taskIDfromProjectAndName()
    printVars(:k=>key, :ts=>ts, :m=>options.m, :pt=>[pid,tid])

    jmsg = %{[#{pid['code']}] #{pid['name']} - #{tid['name']}: #{options.m}}
    hmsg =  %{#{key} #{options.m}: #{options.m}}

    jira.logWork(key, ts, jmsg)
    harvest.logWork(pid['id'], tid['id'], ts, hmsg)

  end
end

#  vim: set et sw=2 ts=2 :
