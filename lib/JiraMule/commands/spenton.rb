require 'chronic'
require 'chronic_duration'
require 'date'
require 'terminal-table'
require 'vine'
require 'JiraMule/jiraUtils'
require 'JiraMule/Tempo'

command :spenton do |c|
  c.syntax = 'jm spenton <keys> [options]'
  c.summary = 'Show work on tickets'
  c.description = %{
  }
  c.option '--start DATE', String, ''
  c.option '--end DATE', String, ''
  c.option '--hours-in-day HOURS', Integer, 'How many hours are in a day (8)'
  c.option '--days-in-week DAYS', Integer, 'How many days are in a week (5)'

  c.action do |args, options|
    options.default :start => 'yesterday',
      :end => 'today',
      :hours_in_day => 8,
      :days_in_week => 5

    jira = JiraMule::JiraUtils.new
    tempo = JiraMule::Tempo.new

    # Get keys to get worklogs from
    keys = jira.expandKeys(args).map{|i| i.upcase}
    jira.printVars(:keys=>keys) if $cfg['tool.verbose']
    # TODO: if multiple keys, build table columns

    dayFrom = Chronic.parse options.start
    dayTo = Chronic.parse options.end
    jira.printVars(:from=>dayFrom,:to=>dayTo) if $cfg['tool.verbose']

    # Using tempo worklog API because it allows fetching just a range.
    # gah.
    # tempo worklog API lets you pick a date range, but not which tickets.
    # Jira worklog is per ticket, but you get everything. (and likely be paginated.)
    # JQL won't get worklogs. (?)
    #
    # So either way, we get too much and need to post filter.
    wls = tempo.workLogs(jira.username, dayFrom.iso8601, dayTo.iso8601)

    # filter out entries not in keys.
    wls = wls.select{|i| keys.include? i.access('issue.key')}
    # Group by the keys
    wls = wls.group_by{|i| i.access('issue.key')}
    wls.transform_values! {|issues| issues.group_by {|i| Date.parse(i[:dateStarted]).mon / 3} } # by month
    wls.transform_values! {|issues| issues.transform_values! {|groups| groups.map{|k| k[:timeSpentSeconds]}.reduce(:+)}}

    wls.transform_values! {|issues| issues.merge({:total=>issues.values.reduce(:+)})}
    ChronicDuration.hours_per_day = options.hours_in_day
    ChronicDuration.days_per_week = options.days_in_week
    wls.transform_values! {|issues| issues.transform_values! {|worked| ChronicDuration.output(worked, :format=>:short)}}

    # Now group by: Quarter, year, ?
    # grped = selected.group_by do |i|
    #   # if by <Quarter>, return date rounded down to <Quarter> start

    #   by_year = Date.parse(i[:dateStarted]).year
    #   by_month = Date.parse(i[:dateStarted]).mon
    #   by_quarter = Date.parse(i[:dateStarted]).mon % 4
    #   return by_quarter
    # end


    # want rows to be tickets, columns to be the groups.
    headers = wls.values.map{|is| is.keys }.flatten.uniq
    # make total the last one
    headers.delete(:total)
    headers.push(:total)

    rows = []
    wls.each {|k,v| rows << [k] + headers.map{|h| v[h]}}

    headers.unshift(:issue)

    tbl = Terminal::Table.new :headings => headers, :rows => rows
    puts tbl
  end
end


#  vim: set ai et sw=2 ts=2 :
