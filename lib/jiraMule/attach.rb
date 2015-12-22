
command :attach do |c|
  c.syntax = 'jira attach [options] [key] [file...]'
  c.summary = 'Attach file to an Issue'
  c.description = ''
  c.example 'Attach a file', %{jira attach BUG-1 foo.log}

  c.action do |args, options|
		jira = JiraUtils.new(args, options)
		key = args.shift
		file = args.shift
		# TODO Work with multiple files. 
		# Upload each as a seperate attachment.
		# ??? -z to zip all files together and upload that?
		# ??? Support - to take STDIN and upload?

		# keys can be with or without the project prefix.
		key = jira.expandKeys([key]).first

		printVars(:key=>key, :file=>file)

		begin
			jira.attach(key, file)
		rescue JiraUtilsException => e
			puts "= #{e}"
			puts "= #{e.response}"
			puts "= #{e.response.inspect}"
			puts "= #{e.request}"
		end

	end
end

#  vim: set sw=2 ts=2 :
