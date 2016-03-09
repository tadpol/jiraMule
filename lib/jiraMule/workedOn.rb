require 'terminal-table'
require 'vine'
require 'pp'

command :progress do |c|
  c.syntax = 'jm progress [options] [<key>]'
  c.summary = 'Show progress on issues'
  c.description = %{}
  # Show only overdue
  # Show only unstarted
  # Show only Started
  c.example 'Show how current project is going', %{jm progress}
  c.example 'Show how work on task 5 is going', %{jm progress 5}

  c.action do |args, options|

	jira = JiraUtils.new(args, options)

    keys = jira.expandKeys(args)
	
	query = %{assignee = #{jira.username} AND project = #{jira.project}}
	query << ' AND (' unless keys.empty?
	query << keys.map{|k| "key=#{k}"}.join(' OR ') unless keys.empty?
	query << ')' unless keys.empty?
	#printVars(:q=>query)
	progresses = jira.getIssues(query, ['key', 'aggregateprogress', 'duedate'])

	rows = progresses.map do |issue|
		[
			issue['key'],
			issue.access('fields.aggregateprogress.total')/3600.0,
			issue.access('fields.aggregateprogress.progress')/3600.0,
			%{#{issue.access('fields.aggregateprogress.percent')}%},
			issue.access('fields.duedate'),
		]
	end.sort{|a,b| a[0].sub(/^\D+(\d+)$/,'\1').to_i <=> b[0].sub(/^\D+(\d+)$/,'\1').to_i }

	# TODO: Highlight rows that are overdue and/or over 100%
	# TODO: Highlight rows that are over 100%
	tbl = Terminal::Table.new :headings=>[:key, :total, :progress, :percent, :due], :rows=>rows
	tbl.align_column(1, :right)
	tbl.align_column(2, :right)
	tbl.align_column(3, :right)
	puts tbl

  end
end

#  vim: set sw=2 ts=2 :
