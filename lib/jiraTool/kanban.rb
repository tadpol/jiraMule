require 'terminal-table'
require 'pp'

command :kanban do |c|
  c.syntax = 'jira query [options] kanban'
  c.summary = 'Show a kanban table'
  c.description = ''
  c.example 'description', 'command example'
	c.option '--[no-]raw', 'Do not prefix queries with project and assigned'
	c.option '-w', '--width WIDTH', Integer, 'Width of the table'
	c.option '-l', '--list', 'List items instead of using a table'
	c.option '-d', '--depth DEPTH', Integer, 'Header depth'
  c.action do |args, options|
		options.default :assignedSelf=>true,
			:width=>HighLine::SystemExtensions.terminal_size[0],
			:depth=>4

		if options.list then
			cW = options.width.to_i - 2
			cWR = cW
			lj = " "
		else
			cW = (options.width.to_i - 16) / 3
			cWR = cW + ((options.width.to_i - 16) % 3)
			lj = "\n "
		end

		jira = JiraUtils.new(args, options)
		qBase = []
		qBase.unshift("assignee = #{jira.username} AND") unless options.raw
		qBase.unshift("project = #{jira.project} AND") unless options.raw

		## Things to do
		q = qBase + [%{(status = Open OR},
							 %{status = "On Deck" OR},
							 %{status = "Waiting Estimation Approval" OR},
							 %{status = "Reopened" OR},
							 %{status = "Testing - Bug Found")}]
		q << %{ORDER BY Rank}
		todo = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}#{lj}#{i['fields']['summary'][0..cWR]}"}

		## Things working on
		q = qBase + [%{status = "In Progress"}]
		q << %{ORDER BY Rank}
		inP = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}#{lj}#{i['fields']['summary'][0..cW]}"}

		## Things in testing
		q = qBase + [%{status = Testing}]
		q << %{ORDER BY Rank}
		test = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}#{lj}#{i['fields']['summary'][0..cW]}"}

		## Things Done
		q = qBase + [%{status = 'Pending Release'}]
		q << %{ORDER BY Rank}
		done = jira.getIssues(q.join(' ')).map{|i| "#{i['key']}#{lj}#{i['fields']['summary'][0..cW]}"}

		if options.list then
			hh = '#' * options.depth.to_i
			puts "#{hh} Done"
			done.each{|i| puts "- #{i}"}

			puts "#{hh} Testing"
			test.each{|i| puts "- #{i}"}
			puts "#{hh} In Progress"
			inP.each{|i| puts "- #{i}"}
			puts "#{hh} To Do"
			todo.each{|i| puts "- #{i}"}

		else
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
end
alias_command :status, :kanban, '--list'

#  vim: set sw=2 ts=2 :
