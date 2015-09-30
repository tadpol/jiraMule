
command :testReady do |c|
	c.syntax = 'jira testReady [options] [version]'
	c.summary = 'Little tool for setting the fix version on testable issues'
	c.description = %{On all issues in the Testing state, set the fix version and optionally reassign.
	}
	c.example 'Set the release version to the latest git tag', %{jira testReady}
	c.example 'Set the release version to "v2.0"', %{jira testReady v2.0}
	c.example 'Also reassign to the default', %{jira testReady -r v2.0}
	c.example 'Also reassign to BOB', %{jira testReady v2.0 --assign BOB}
	c.option '-r', '--[no-]reassign', 'Also reassign to Default'
	c.option '-a', '--assign USER', 'Assign to USER'
	c.action do |args, options|
		options.default :reassign => false

		if args[0].nil? then
			version = GitUtils.getVersion
			newver = ask("\033[1m=?\033[0m Enter the version you want to release (#{version}) ")
			version = newver unless newver == ''
		else
			version = args[0]
		end

		jira = JiraUtils.new(args, options)
		project = jira.project

		if !options.assign.nil? then
			users = jira.checkUser(options.assign)
			if users.length > 1 then
				printErr "User name '#{options.assign}' is ambigious."
				printVars('Could be'=>users)
				exit 4
			end
			if users.length <= 0 then
				printErr "No users match #{options.assign}"
				exit 4
			end
			options.assign = users[0]
			printVars(:assign=>options.assign)
		end

		jira.createVersion(project, version)

		### Find all unreleased issues
		query ="assignee = #{jira.username} AND project = #{project} AND status = Testing" 
		keys = jira.getIssues(query).map {|item| item['key'] }
		printVars({:keys=>keys})

		### Mark issues as fixed by version
		updt = { 'fixVersions'=>[{'add'=>{'name'=>version}}] }
		## assign to '-1' to have Jira automatically assign it
		updt['assignee'] = [{'set'=>{'name'=>'-1'}}] if options.reassign
		updt['assignee'] = [{'set'=>{'name'=>options.assign}}] if options.assign

		printVars(:update=>updt) if options.verbose

		jira.updateKeys(keys, updt)

	end
end

#  vim: set sw=2 ts=2 :
