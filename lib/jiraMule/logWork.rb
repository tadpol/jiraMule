#
require 'chronic_duration'
require 'vine'
require 'date'

command :logwork do |c|
  c.syntax = 'jm logwork [options] <key> <time spent...>'
  c.summary = 'Log work spent'
  c.description = %{Log time spent on a issue, sending update to both jira and harvest}
  c.option '-m', '--message MSG', String, 'Message to add to work log'
  c.option '--date DATE', String, 'When this work was done'
  #c.option '--[no-]harvest', %{Don't post time to harvest}
  c.example 'Log some work done on an issue', %{jm logwork BUG-42 1h 12m}

  c.action do |args, options|
    options.defaults :harvest => true, :message => ''
    jira = JiraUtils.new(args, options)
    harvest = HarvestUtils.new(args, options)

    key = jira.expandKeys(args).shift
    ts = ChronicDuration.parse(args.join(' '))

    unless options.date.nil? then
      options.date = DateTime.parse(options.date)
    end

    # ask the key where work should go.
    issues = jira.getIssues("key='#{key}'", ['key', 'labels'])
    labels = issues.first.access('fields.labels')
    pid=nil
    tid=nil
    labels.each do |lbl|
      if lbl =~ /^harvest:(\d+):(\d+)$/ then
        pid=$1.to_i
        tid=$2.to_i
      end
    end
    printVars(:pid=>pid, :tid=>tid) if options.verbose

    # if pid and/or tid are still nil here, the values in the project config will be
    # used instead.
    pid, tid = harvest.taskIDfromProjectAndName(pid, tid)
    raise "Cannot figure out which havest code to use" if pid.nil? or tid.nil?
    printVars(:k=>key, :ts=>ts, :m=>options.message, :pt=>[pid['name'],tid['name']])

    jmsg = %{[#{pid['code']}] #{pid['name']} - #{tid['name']}: #{options.message}}
    hmsg =  %{#{key}: #{options.message}}

    begin
      jira.logWork(key, ts, jmsg, options.date)
      harvest.logWork(pid['id'], tid['id'], ts, hmsg, options.date)
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

    proj = args[0]
    proj = harvest.project if proj == "" # allow project name from cfg
    task = args[1]
    task = harvest.task if task == "" # allow task name from cfg

    printVars(:project=>proj, :task=>task)
    pid, tid = harvest.taskIDfromProjectAndName(proj, task)
    raise "Cannot find a project \"#{proj}\"" if pid.nil?
    raise "Cannot find a task \"#{task}\"" if tid.nil?
    printVars(:pid=>pid['id'], :tid=>tid['id'])

    keys = jira.expandKeys(args[2..-1])
    printVars(:keys=>keys)

    hl = {:labels=>[{:add=>"harvest:#{pid['id']}:#{tid['id']}"}]}
    jira.updateKeys(keys, hl)

  end
end
alias_command :mw, :mapwork

#  vim: set et sw=2 ts=2 :
