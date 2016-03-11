
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
			direct = trans.select {|item| item['name'] == to }
			if not direct.empty? then
				# We can just go right there.
				id = direct.first['id']
				jira.transition(key, to)
				# TODO: deal with required field.
			else

				# TODO: Get the workflow; ah, might not be able to get this.
				# Cannot get workflows, how else to do this?

				# TODO: Find a path from here to there.
			end
		end
	end
end

#  vim: set sw=2 ts=2 :

