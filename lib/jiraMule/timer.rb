#

command :time do |c|
  c.syntax = 'jira time [options] <key> '
  c.summary = 'Log work spent'
  c.description = %{Log time spent on a issue, sending update to both jira and harvest}
  c.option '-m', 'message to add to work log'
  c.option '--task', 'Which Harvest task to track against'
  c.option '--[no-]harvest', %{Don't post time to harvest}
  c.example 'Log some work done on an issue', %{jira time BUG-42 1h 12m}

  c.action do |args, options|
    options.defaults :harvest => true
    jira = JiraUtils.new(args, options)
    harvest = HarvestUtils.new(args, options)
  end
end

#  vim: set et sw=2 ts=2 :
