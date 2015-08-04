require 'terminal-table'
require 'pp'

command :kanban do |c|
  c.syntax = 'jira query [options] kanban'
  c.summary = 'Show a kanban table'
  c.description = ''
  c.example 'description', 'command example'
	c.option '--[no-]raw', 'Do not prefix queries with project and assigned'
	c.option '-w', '--width WIDTH', 'Width of the table'
  c.action do |args, options|
		options.default :assignedSelf=>true,
			:width=>HighLine::SystemExtensions.terminal_size[0]

		# cleanup for rounding.
		cW = (options.width.to_i - 13) / 3

		jira = JiraUtils.new(args, options)
		qBase = []
		qBase.unshift("assignee = #{jira.username} AND") unless options.raw
		qBase.unshift("project = #{jira.project} AND") unless options.raw

		## things to do
		q = qBase + [%{(status = open OR status = "On Deck" OR status = "Waiting Estimation Approval" OR status = "Testing - Bug Found")}]
		todo = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}\n #{i['fields']['summary'][0..cW]}"}

		## Things working on
		q = qBase + [%{status = "In Progress"}]
		inP = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}\n #{i['fields']['summary'][0..cW]}"}

		## Things in testing
		q = qBase + [%{status = Testing}]
		test = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}\n #{i['fields']['summary'][0..cW]}"}

		## pad out short
		longest = [todo.length, inP.length, test.length].max
		todo.fill(' ', todo.length .. longest) if todo.length <= longest
		inP.fill(' ', inP.length .. longest) if inP.length <= longest
		test.fill(' ', test.length .. longest) if test.length <= longest

		rows = [todo, inP, test].transpose
		table = Terminal::Table.new :headings => ["TODO", "In Progress", "Testing"], :rows=>rows
		puts table

  end
end
#  vim: set sw=2 ts=2 :
