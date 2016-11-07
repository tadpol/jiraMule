require 'terminal-table'

command :query do |c|
  c.syntax = 'jm query [options] query'
  c.summary = 'Get the keys from a jira query'
  c.description = 'Run a query. '
  c.example 'Get Open issues and dump everything', %{jm query status=Open --fields "" --json}
  c.option '--[no-]raw', 'Do not prefix query with project and assignee'
  c.option '--[no-]json', 'Output json reply instead of summary'
  c.option '--fields FIELDS', Array, 'Which fields to return.'
  c.option '--all_fields', 'Return all fields'

  c.action do |args, options|
    options.defaults :json => false, :all_fields => false

    jira = JiraMule::JiraUtils.new(args, options)
    args.unshift("assignee = #{jira.username} AND") unless options.raw
    args.unshift("project = #{jira.project} AND") unless options.raw
    q = args.join(' ')
    if options.all_fields then
      issues = jira.getIssues(q, [])
    elsif options.fields then
      issues = jira.getIssues(q, options.fields)
    else
      issues = jira.getIssues(q)
    end
    if options.json then
      puts JSON.dump(issues)
    else
      keys = issues.map {|item| "#{item[:key]} #{(item.access('fields.summary') or '')}" }
      keys.each {|k| puts k}

#      headers = [:key]
#      rows = issues.map do |item|
#        rw = [item[:key]]
#        item[:fields].each_pair do |fname, fvalue|
#          headers << fname unless headers.include? fname
#          rw << fvalue
#        end
#        rw
#      end
#
#      puts Terminal::Table.new :headings => headers, :rows=>rows

    end
  end
end
alias_command :q, :query

#  vim: set sw=2 ts=2 :
