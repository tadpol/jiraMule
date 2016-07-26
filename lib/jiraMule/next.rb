require 'vine'
require 'pp'

command :next do |c|
	c.syntax = 'jm next [options] [keys]'
	c.summary = 'Move issue to the next state'
	c.description = %{
	Move to the next state. For states with multiple exits, use the 'preferred' one.
	}
	c.example 'Move BUG-4 into the next state.', %{jm next BUG-4}
	c.option '-m', '--map MAPNAME', String, 'Which workflow map to use'
	c.action do |args, options|
		options.default :map=>'PSStandard'
		jira = JiraUtils.new(args, options)

		# keys can be with or without the project prefix.
		keys = jira.expandKeys(args)
		printVars(:keys=>keys)
		return if keys.empty?

		keys.each do |key|
			# First see if there is a single exit. If so, just do that.
			trans = jira.transitionsFor(key)
			# TODO: ignore Blocked and Closed because everything can go to them.
			check = trans.reject{|t| t['name'] == "Closed" or t['name'] == "Blocked" }
			if check.length == 1 then
				id = check.first['id']
				puts "Taking single exit: '#{check.first['name']}'" if options.verbose
				jira.transition(key, id)
				# TODO: deal with required fields.
			else

				# Where we are.
				query = "assignee = #{jira.username} AND project = #{jira.project} AND "
				query << "key = #{key}"
				issues = jira.getIssues(query, ["status"])
				type = issues.first.access('fields.issuetype.name')
				at = issues.first.access('fields.status.name')

				# Look up what the preferred next step is, and do that.
				nxt = $cfg[".jira.next.#{options.map}.#{at}"]
				raise "Not sure which state is next after #{at} in #{options.map}" if nxt.nil?

				direct = trans.select {|item| jira.fuzzyMatchStatus(item, nxt) }
				raise "Broken transition step on #{key} to #{nxt}" if direct.empty?
				id = direct.first['id']
				puts "Transitioning #{key} to #{direct.first['name']} (#{id})" if options.verbose
				jira.transition(key, id)
				# TODO: deal with required fields.

			end
		end
	end
end


#  vim: set sw=2 ts=2 :

