
command :release do |c|
  c.syntax = 'jm release [options]'
  c.summary = 'Little tool for releasing a version in Jira'
  c.description = ''
  c.example 'description', 'command example'
  c.option '--some-switch', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Jira::Commands::Release

		version = GitUtils.getVersion
		newver = ask("\033[1m=?\033[0m Enter the version you want to release (#{version}) ")
		version = newver unless newver == ''

		project = $cfg['.jira.project']
		jira = JiraUtils.new(args, options)

		jira.createVersion(project, version)

		### Find all unreleased issues
		query ="assignee = #{jira.username} AND project = #{project} AND (status = Resolved OR status = Closed) AND fixVersion = EMPTY" 
		keys = jira.getIssues(query).map {|item| item['key'] }
		printVars({:keys=>keys})

		### Mark issues as fixed by version
		updt = { 'fixVersions'=>[{'add'=>{'name'=>version}}] }
		jira.updateKeys(keys, updt)

		### This is old process residue.  So should consider removing
		if $cfg['.jira.alsoClose'] == true
			puts "Also closing." if options.verbose
			query = "assignee = #{jira.username} AND project = #{project} AND status = Resolved AND fixVersion != EMPTY" 
			keys = jira.getIssues(query).map {|item| item['key'] }
			printVars({:Rkeys=>keys})

			if !keys.empty?
				jira.transition(keys, 'Closed')
			end
		end

  end
end

#  vim: set sw=2 ts=2 :
