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
		options.default :width=>HighLine::SystemExtensions.terminal_size[0], :depth=>4

		if options.list then
			cW = options.width.to_i - 2
			cWR = cW
			lj = " "
		else
			cW = (options.width.to_i - 16) / 3
			cWR = cW + ((options.width.to_i - 16) % 3)
			lj = "\n "
		end

		# Columms
		columns = {
			:Done => [%{status = 'Pending Release'}],
			:Testing => [%{status = Testing}],
			:InProgress => [%{status = "In Progress"}],
			:Todo => [%{(status = Open OR},
							 %{status = Reopened OR},
							 %{status = "On Deck" OR},
							 %{status = "Waiting Estimation Approval" OR},
							 %{status = "Reopened" OR},
							 %{status = "Testing (Signoff)" OR},
							 %{status = "Testing (Review)" OR},
							 %{status = "Testing - Bug Found")}],
		}

		jira = JiraUtils.new(args, options)
		qBase = []
		qBase.unshift("assignee = #{jira.username} AND") unless options.raw
		qBase.unshift("project = #{jira.project} AND") unless options.raw


		results = {}
		columns.each_pair do |name, query|
			q = qBase + query + [%{ORDER BY Rank}]
			issues = jira.getIssues(q.join(' ')).map do |i|
				"#{i['key']}#{lj}#{i['fields']['summary'][0..cWR]}"
			end
			results[key] = issues
		end

		if options.list then
			hh = '#' * options.depth.to_i
			puts "#{hh} Done"
			results[:Done].each{|i| puts "- #{i}"}
			puts "#{hh} Testing"
			results[:Testing].each{|i| puts "- #{i}"}
			puts "#{hh} In Progress"
			results[:InProgress].each{|i| puts "- #{i}"}
			puts "#{hh} To Do"
			results[:Todo].each{|i| puts "- #{i}"}

		else
			## pad out short
			longest = [results[:Todo].length, results[:InProgress].length, results[:Testing].length].max
			results[:Todo].fill(' ', results[:Todo].length .. longest) if results[:Todo].length <= longest
			results[:InProgress].fill(' ', results[:InProgress].length .. longest) if results[:InProgress].length <= longest
			results[:Testing].fill(' ', results[:Testing].length .. longest) if results[:Testing].length <= longest

			rows = [results[:Todo], results[:InProgress], results[:Testing]].transpose
			table = Terminal::Table.new :headings => ["TODO", "In Progress", "Testing"], :rows=>rows
			puts table
		end

  end
end
alias_command :status, :kanban, '--list'

#  vim: set sw=2 ts=2 :
