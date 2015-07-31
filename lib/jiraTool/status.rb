
command :status do |c|
  c.syntax = 'jira status [options]'
  c.summary = 'List out the task status for including in Release Notes'
  c.description = ''
	c.option '-t DEPTH', Integer, 'Header depth'
  c.action do |args, options|
    # Do something or c.when_called Jira::Commands::Status
		options.defaults :t=>4

		project = $cfg['.jira.project']
	
			hh = '#' * options.t.to_i

			puts "#{hh} Done"
			query ="assignee = #{$cfg.username} AND project = #{project} AND status = 'Pending Release'" 
			keys = getIssueKeys(query)
			keys.each {|k| puts "- #{k}"}

			puts "#{hh} Testing"
			query ="assignee = #{$cfg.username} AND project = #{project} AND status = Testing" 
			keys = getIssueKeys(query)
			keys.each {|k| puts "- #{k}"}

			puts "#{hh} In Progress"
			query ="assignee = #{$cfg.username} AND project = #{project} AND status = 'In Progress'" 
			keys = getIssueKeys(query)
			keys.each {|k| puts "- #{k}"}

			puts "#{hh} To Do"
			query ="assignee = #{$cfg.username} AND project = #{project} AND status = Open" 
			keys = getIssueKeys(query)
			keys.each {|k| puts "- #{k}"}
  end
end
#  vim: set sw=2 ts=2 :
