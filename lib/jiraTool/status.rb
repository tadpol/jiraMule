
command :status do |c|
  c.syntax = 'jira status [options]'
  c.summary = 'List out the task status for including in Release Notes'
  c.description = ''
	c.option '--depth DEPTH', Integer, 'Header depth'
  c.action do |args, options|
    # Do something or c.when_called Jira::Commands::Status
		options.default :depth=>4

		project = $cfg['.jira.project']
		jira = JiraUtils.new(args, options)

		hh = '#' * options.depth.to_i

		puts "#{hh} Done"
		query ="assignee = #{jira.username} AND project = #{project} AND status = 'Pending Release'" 
		issues = jira.getIssues(query)
		issues.each {|item| puts "- #{item['key']} #{item.access('fields.summary')}" }

		puts "#{hh} Testing"
		query ="assignee = #{jira.username} AND project = #{project} AND status = Testing" 
		issues = jira.getIssues(query)
		issues.each {|item| puts "- #{item['key']} #{item.access('fields.summary')}" }

		puts "#{hh} In Progress"
		query ="assignee = #{jira.username} AND project = #{project} AND status = 'In Progress'" 
		issues = jira.getIssues(query)
		issues.each {|item| puts "- #{item['key']} #{item.access('fields.summary')}" }

		puts "#{hh} To Do"
		query ="assignee = #{jira.username} AND project = #{project} AND status = Open" 
		issues = jira.getIssues(query)
		issues.each {|item| puts "- #{item['key']} #{item.access('fields.summary')}" }
	end
end
#  vim: set sw=2 ts=2 :
