require 'vine'
require 'pp'

command :goto do |c|
  c.syntax = 'jm goto [options] [status] [keys]'
  c.summary = 'Move issue to a status; making multiple transitions if needed'
  c.description = %{
	Named for the bad command that sometime there is nothing better to use.

	Your issue has a status X, and you need it in Y, and there are multiple steps from
	X to Y.  Why would you do something a computer can do better?  Hence goto.

	The down side is there is no good way to automatically get mutli-step transitions.
	So these need to be added to your config.
	}
  c.example 'Move BUG-4 into the In Progress state.', %{jm goto 'In Progress' BUG-4}
	c.option '-m', '--map MAPNAME', String, 'Which workflow map to use'
  c.action do |args, options|
		options.default :m=>'PSStandard'
		jira = JiraUtils.new(args, options)
		to = args.shift

		# keys can be with or without the project prefix.
		keys = jira.expandKeys(args)
		printVars(:to=>to, :keys=>keys)
		raise "No keys to transition" if keys.empty?

		keys.each do |key|
			# First see if we can just go there.
			trans = jira.transitionsFor(key)
			direct = trans.select {|item| jira.fuzzyMatchStatus(item, to) }
			if not direct.empty? then
				# We can just go right there.
				id = direct.first['id']
				jira.transition(key, id)
				# TODO: deal with required field.
			else

				# where we are.
				query = "assignee = #{jira.username} AND project = #{jira.project} AND "
				query << "key = #{key}"
				issues = jira.getIssues(query, ["status"])
				type = issues.first.access('fields.issuetype.name')
				at = issues.first.access('fields.status.name')

				# Get the 
				transMap = jira.getPath(at, to, options.map)

				# Now move thru
				transMap.each do |step|
					trans = jira.transitionsFor(key)
					direct = trans.select {|item| jira.fuzzyMatchStatus(item, step) }
					raise "Broken transition step on #{key} to #{step}" if direct.empty?
					id = direct.first['id']
					jira.transition(key, id)
					# TODO: deal with required field.
				end

			end
		end
	end
end
alias_command :move, :goto

command :mapGoto do |c|
  c.syntax = 'jm mapGoto [options]'
  c.summary = 'Attempt to build a goto map'
  c.description = %{
	This command is incomplete.  The goal here is to auto-build the transision maps
	for multi-step gotos.

	Right now it is just dumping stuff.

	}
  c.action do |args, options|
		jira = JiraUtils.new(args, options)

		# Get all of the states that issues can be in.
		# Try to find an actual issue in each state, and load the next transitions from
		# it.
		#
		types = jira.statusesFor(jira.project)
		
		# There is only one workflow for all types it seems.

		# We just need the names, so we'll merge down.
		statusNames = {}

		types.each do |type|
			statuses = type['statuses']
			next if statuses.nil?
			next if statuses.empty?
			statuses.each {|status| statusNames[ status['name'] ] = 1}
		end

		statusNames.each_key do |status|
			puts "    #{status}"
			query = %{project = #{jira.project} AND status = "#{status}"}
			issues = jira.getIssues(query, ["key"])
			if issues.empty? then
				#?
			else
				key = issues.first['key']
				# get transisitons.
				trans = jira.transitionsFor(key)
				trans.each {|tr| puts "      -> #{tr['name']} [#{tr['id']}]"}
			end
		end

	end
end

#  vim: set sw=2 ts=2 :

