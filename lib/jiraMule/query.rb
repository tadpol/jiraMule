
command :query do |c|
  c.syntax = 'jm query [options] query'
  c.summary = 'Get the keys from a jira query'
  c.description = 'Run a query. '
	c.example 'Get Open issues and dump everything', %{jm query status=Open --fields "" --json}
	c.option '--[no-]raw', 'Do not prefix query with project and assignee'
	c.option '--[no-]json', 'Output json reply instead of summary'
	c.option '--fields FIELDS', Array, ''
  c.action do |args, options|
		options.defaults :json => false
		jira = JiraUtils.new(args, options)
		args.unshift("assignee = #{jira.username} AND") unless options.raw
		args.unshift("project = #{jira.project} AND") unless options.raw
		q = args.join(' ')
		if options.fields then
			issues = jira.getIssues(q, options.fields)
		else
			issues = jira.getIssues(q)
		end
		if options.json then
			puts JSON.dump(issues)
		else
			keys = issues.map {|item| item['key'] + ' ' + item.access('fields.summary')}
			keys.each {|k| puts k}
		end
  end
end
alias_command :q, :query

#  vim: set sw=2 ts=2 :
