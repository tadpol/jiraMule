require 'terminal-table'
require 'mustache'
require 'pp'

command :kanban do |c|
  c.syntax = 'jira query [options] kanban'
  c.summary = 'Show a kanban table'
  c.description = ''
  c.example 'description', 'command example'
	c.option '--[no-]raw', 'Do not prefix queries with project and assigned'
	c.option '-w', '--width WIDTH', Integer, 'Width of the terminal'
	c.option '-s', '--style STYLE', String, 'Which style to use'
	c.option '--heading STYLE', String, 'Format for heading'
	c.option '--item STYLE', String, 'Format for items'

  c.action do |args, options|
		options.default :width=>HighLine::SystemExtensions.terminal_size[0],
			:style => 'kanban'

		# Table of Styles. Appendable via config file. ??and command line??
		allOfThem = {
			:status => {
				:format => {
					:heading => "#### {{column}}",
					:item => "- {{key}} {{summary}}",
					:order => [:Done, :Testing, :InProgress, :Todo],
				},
				:columns => {
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
				},

			},
			:kanban => {
				:format => {
					:heading => "{{column}}",
					:item => "{{key}}\n {{summary}}",
					:order => [:Todo, :InProgress, :Testing],
					:usetable => true
				},
				:columns => {
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
				},
			},
			:taskpaper => {
				:format => {
					:heading => "{{column}}:",
					:item => "- {{summary}} @jira({{key}})",
				},
				:columns => {
					:InProgress => [%{status = "In Progress"}],
				}
			},
		}


		### Fetch the issues for each column
		columns = allOfThem[options.style.to_sym][:columns]
		jira = JiraUtils.new(args, options)
		qBase = []
		qBase.unshift("assignee = #{jira.username} AND") unless options.raw
		qBase.unshift("project = #{jira.project} AND") unless options.raw
		results = {}
		columns.each_pair do |name, query|
			q = qBase + query + [%{ORDER BY Rank}]
			issues = jira.getIssues(q.join(' '))
			results[name] = issues
		end

		### Now format the output
		format = allOfThem[options.style.to_sym][:format]
		#### look for command line overrides
		format[:heading] = options.heading if options.heading
		format[:item] = options.item if options.item

		#### Setup ordering
		format[:order] = columns.keys.sort unless format.has_key? :order

		#### setup column widths
		cW = options.width.to_i
		cW = -1 if cW == 0
		cWR = cW
		if format[:usetable] and cW > 0 then
			borders = 4 + (columns.count * 3);   # 2 on left, 2 on right, 3 for each internal
			cW = (cW - borders) / columns.count
			cWR = cW + ((cW - borders) % columns.count)
		end

		#### Format Items
		formatted={}
		results.each_pair do |name, issues|
			formatted[name] = issues.map do |issue|
				line = Mustache.render(format[:item], issue.merge(issue['fields']))
				#### Trim length?
				if format[:order].last == name
					line[0..cWR]
				else
					line[0..cW]
				end
			end
		end

		#### Print
		if format.has_key?(:usetable) and format[:usetable] then
			# Table type
			#### Pad
			longest = formatted.values.map{|l| l.length}.max
			formatted.each_pair do |name, issues|
				if issues.length <= longest then
					issues.fill(' ', issues.length .. longest)
				end
			end

			#### Transpose
			rows = format[:order].map{|n| formatted[n]}.transpose
			puts Terminal::Table.new :headings => format[:order], :rows=>rows

		else
			# List type
			format[:order].each do |columnName|
				puts Mustache.render(format[:heading], :column => columnName.to_s)
				formatted[columnName].each {|issue| puts issue}
			end
		end

  end
end
alias_command :status, :kanban, '--style', 'status'

#  vim: set sw=2 ts=2 :
