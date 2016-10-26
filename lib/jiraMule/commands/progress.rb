require 'date'
require 'terminal-table'
require 'vine'
require 'JiraMule/jiraUtils'

command :progress do |c|
  c.syntax = 'jm progress [options] [<key>]'
  c.summary = 'Show progress on issues'
  c.description = %{}
  # Show only overdue (today > duedate)
  # Show only unstarted (timespent == 0)
  # Show only Started (timespent > 0)
  c.option '-s', '--status STATUSES', Array, 'Which status to limit to'
  c.example 'Show how current project is going', %{jm progress}
  c.example 'Show how work on task 5 is going', %{jm progress 5}

  c.action do |args, options|
    options.default :status=>[]

  jira = JiraMule::JiraUtils.new(args, options)
  keys = jira.expandKeys(args)
  if keys.empty? and options.status.empty? then
    options.status << 'In Progress'
  end

  query = %{assignee = #{jira.username} AND project = #{jira.project}}
  query << ' AND (' unless keys.empty?
  query << keys.map{|k| "key=#{k}"}.join(' OR ') unless keys.empty?
  query << ')' unless keys.empty?
  query << ' AND (' unless options.status.empty?
  query << options.status.map{|s| %{status="#{s}"}}.join(' OR ') unless options.status.empty?
  query << ')' unless options.status.empty?
  #jira.printVars(:q=>query)
  progresses = jira.getIssues(query, ['key', 'workratio', 'aggregatetimespent',
                                     'duedate', 'aggregatetimeoriginalestimate'])

  rows = progresses.map do |issue|
    estimate = (issue.access('fields.aggregatetimeoriginalestimate') or 0)/3600.0
    progress = (issue.access('fields.aggregatetimespent') or 0)/3600.0
    due = issue.access('fields.duedate')
    percent = issue.access('fields.workratio')
    if percent < 0 then
      estimate = progress if estimate == 0
      percent = (progress / estimate * 100).floor
    end
    ret = [ issue[:key], "%.2f"%[estimate], "%.2f"%[progress],
          %{#{"%.1f"%[percent]}%}, due ]
    if progress > estimate or (not due.nil? and Date.new >= Date.parse(due)) then
      ret.map!{|v| %{\033[1m#{v}\033[0m}}
    end
    ret
  end.sort{|a,b| a[0].sub(/^\D+(\d+)$/,'\1').to_i <=> b[0].sub(/^\D+(\d+)$/,'\1').to_i }

  tbl = Terminal::Table.new :headings=>[:key, :estimated, :progress, :percent, :due], :rows=>rows
  tbl.align_column(1, :right)
  tbl.align_column(2, :right)
  tbl.align_column(3, :right)
  puts tbl

  end
end

#  vim: set sw=2 ts=2 :
