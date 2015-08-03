
command :testReady do |c|
	c.syntax = 'jira testReady [options] [version]'
	c.summary = 'Little tool for setting the fix version on testable issues'
	c.description = ''
	c.example 'description', 'command example'
	c.option '-r --reassign', 'Also reassign to Default'
#	c.option '-a --assign USER', 'Assign to '
	c.action do |args, options|
		# Do something or c.when_called Jira::Commands::Testready
		options.defaults :reassign => true

		version = GitUtils.getVersion
		newver = ask("\033[1m=?\033[0m Enter the version you want to release (#{version}) ")
		version = newver unless newver == ''

		project = $cfg['.jira.project']
		jira = JiraUtils.new(args, options)

		jira.createVersion(version)

		### Find all unreleased issues
		query ="assignee = #{jira.username} AND project = #{project} AND status = Testing" 
		keys = jira.getIssues(query).map {|item| item['key'] }
		printVars({:keys=>keys})

		### Mark issues as fixed by version
		updt = { 'fixVersions'=>[{'add'=>{'name'=>version}}] }
		## assign to '-1' to have Jira automatically assign it
		updt['assignee'] = [{'set'=>{'name'=>'-1'}}] if options.reassign

		jira.updateKeys(keys, updt)

	end
end

#  vim: set sw=2 ts=2 :
