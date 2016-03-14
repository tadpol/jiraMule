require 'vine'

command :goto do |c|
  c.syntax = 'jira goto [options] [status] [key]'
  c.summary = 'Move issue to a status; making multiple transitions if needed'
  c.description = %{
	Named for the bad command that sometime there is nothing better to use.

	Your issue has a status X, and you need it in Y, and there are multiple steps from
	X to Y.  Why would you do something a computer can do better?  Hence goto.
	}
  c.example 'Move BUG-4 into the In Progress state.', %{jm move 'In Progress' BUG-4}
  c.action do |args, options|
		jira = JiraUtils.new(args, options)
		to = args.shift

		# keys can be with or without the project prefix.
		keys = jira.expandKeys(args)
		printVars(:to=>to, :k=>keys)
		return if keys.empty?

		keys.each do |key|
			# First see if we can just go there.
			trans = jira.transitionsFor(key)
			direct = trans.select {|item| item['name'] == to || item['id'] == to }
			if not direct.empty? then
				# We can just go right there.
				id = direct.first['id']
				jira.transition(key, id)
				# TODO: deal with required field.
			else

				# TODO: Get the workflow; ah, might not be able to get this.
				# Cannot get workflows, how else to do this? We'll load it in the config i
				# think.

				# where we are.
				query = "assignee = #{jira.username} AND project = #{jira.project} AND "
				query << "key = #{key}"
				issues = jira.getIssues(query, ["status"])
				at= issues.first.access('fields.status.name')

				# lookup a transition map
				transMap = $cfg[".jira.goto.#{at}.#{to}"]
				raise "No transition map for #{key} from #{at} to #{to}" if transMap.nil?

				transMap.each do |step|
					trans = jira.transitionsFor(key)
					direct = trans.select {|item| item['name'] == step || item['id'] == step }
					raise "Broken transition step on #{key} to #{step}" if direct.empty?
					id = direct.first['id']
					jira.transition(key, id)
				end

			end
		end
	end
end

#  vim: set sw=2 ts=2 :

