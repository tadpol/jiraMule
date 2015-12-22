
command :attach do |c|
  c.syntax = 'jira attach [options] [key] [file...]'
  c.summary = 'Attach file to an Issue'
  c.description = ''
  c.example 'Attach a file', %{jira attach BUG-1 foo.log}

  c.action do |args, options|
		jira = JiraUtils.new(args, options)
		key = args.shift
		file = args.shift

		# keys can be with or without the project prefix.
		key = jira.expandKeys([key]).first

		printVars(:key=>key, :file=>file)

		jira.attach(key, file)

	end
end

#  vim: set sw=2 ts=2 :
