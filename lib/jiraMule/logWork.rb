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
    printVars(:k=>key, :ts=>ts, :m=>options.m, :pt=>[pid['name'],tid['name']])

    jmsg = %{[#{pid['code']}] #{pid['name']} - #{tid['name']}: #{options.m}}
    hmsg =  %{#{key} #{options.m}: #{options.m}}

    begin
      jira.logWork(key, ts, jmsg)
      harvest.logWork(pid['id'], tid['id'], ts, hmsg)
    rescue JiraUtilsException => e
      pp e.response.body
      
    rescue HarvestUtilsException => e
      pp e.response.body
    end

  end
end
alias_command :lw, :logwork

command :mapwork do |c|
  c.syntax = 'jm mapwork [options] "<harvest project>" "<harvest task>" <keys>'
  c.summary = 'Store the harvest codes as a label in Jira.'
  c.description = %{
  Different Jira Tasks get different Harvest codes all in the same project.

  What a mess.

  This easily stores which harvest project and task a Jira task should map to.

  Logwork will then use this mapping.
}


  c.action do |args, options|
    jira = JiraUtils.new(args, options)
    harvest = HarvestUtils.new(args, options)

    printVars(:p=>args[0], :t=>args[1])
    pid, tid = harvest.taskIDfromProjectAndName(args[0], args[1])
    printVars(:pid=>pid['id'], :tid=>tid['id'])

    keys = jira.expandKeys(args[2..-1])
    printVars(:k=>keys)

    hl = {:labels=>[{:add=>"harvest:#{pid['id']}:#{tid['id']}"}]}
    jira.updateKeys(keys, hl)

  end
end
alias_command :mw, :mapwork

#  vim: set et sw=2 ts=2 :
