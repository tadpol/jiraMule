
command :move do |c|
  c.syntax = 'jira move [options] [transition] [keys]'
  c.summary = 'Move issues into a state.'
  c.description = ''
  c.example 'Move BUG-1 and BUG-4 into the In Progress state.', %{jira move 'In Progress' BUG-1 BUG-4}
  c.action do |args, options|
		jira = JiraUtils.new(args, options)
		to = args.shift

		# keys can be with or without the project prefix.
		keys = jira.expandKeys(args)
		printVars(:to=>to, :k=>keys)

		# transitions keys.
		jira.transition(keys, to)

		# optinally reassign them

	end
end

#  vim: set sw=2 ts=2 :
