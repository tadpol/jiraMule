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
  c.option '--hours-in-day HOURS', Integer, 'How many hours are in a day (24)'
  c.option '--days-in-week DAYS', Integer, 'How many days are in a week (24)'
  c.option '--[no-]list', 'Show all the days'

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

    wls = tempo.workLogs(jira.username, dayFrom.iso8601, dayTo.iso8601)

    # filter out entries not in keys.
    selected = wls.select{|i| keys.include? i.access('issue.key')}

    total = selected.map{|k| k[:timeSpentSeconds] }.reduce(:+)
    total = 0 if total.nil?
    ChronicDuration.hours_per_day = options.hours_in_day
    ChronicDuration.days_per_week = options.days_in_week
    total = ChronicDuration.output(total, :format=>:short)

    unless options.list then
      say total
    else
      lst = selected.map do |k|
        [ Chronic.parse(k[:dateStarted]).strftime('%F'),
          ChronicDuration.output(k[:timeSpentSeconds])]
      end
      tbl = Terminal::Table.new do |t|
        t.rows = lst
        t.add_separator
        t.add_row ['TOTAL:', total]
      end
      puts tbl
    end

  end
end


#  vim: set ai et sw=2 ts=2 :
