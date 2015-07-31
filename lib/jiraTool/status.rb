
command :status do |c|
  c.syntax = 'jira status [options]'
  c.summary = 'List out the task status for including in Release Notes'
  c.description = ''
	c.option '-t DEPTH', Integer, 'Header depth'
  c.action do |args, options|
    # Do something or c.when_called Jira::Commands::Status
		options.defaults :t=>4

		project = $cfg['.jira.project']
		jira = JiraUtils.new(args, options)

		hh = '#' * options.t.to_i # FIXME: this isn't working.

		puts "#{hh} Done"
		query ="assignee = #{jira.username} AND project = #{project} AND status = 'Pending Release'" 
		issues = jira.getIssues(query)
		keys = issues.map {|item| item['key'] + ' ' + item.access('fields.summary')}
		keys.each {|k| puts "- #{k}"}

		puts "#{hh} Testing"
		query ="assignee = #{jira.username} AND project = #{project} AND status = Testing" 
		issues = jira.getIssues(query)
		keys = issues.map {|item| item['key'] + ' ' + item.access('fields.summary')}
		keys.each {|k| puts "- #{k}"}

		puts "#{hh} In Progress"
		query ="assignee = #{jira.username} AND project = #{project} AND status = 'In Progress'" 
		issues = jira.getIssues(query)
		keys = issues.map {|item| item['key'] + ' ' + item.access('fields.summary')}
		keys.each {|k| puts "- #{k}"}

		puts "#{hh} To Do"
		query ="assignee = #{jira.username} AND project = #{project} AND status = Open" 
		issues = jira.getIssues(query)
		keys = issues.map {|item| item['key'] + ' ' + item.access('fields.summary')}
		keys.each {|k| puts "- #{k}"}
	end
end
#  vim: set sw=2 ts=2 :
