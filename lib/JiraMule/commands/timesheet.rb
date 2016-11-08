require 'chronic_duration'
require 'date'
require 'terminal-table'
require 'vine'
require 'JiraMule/jiraUtils'

command :timesheet do |c|
  c.syntax = 'jm timesheet [options]'
  c.summary = 'Show work done this week'
  c.description = %{Show the work done this week
  }
  c.example 'Show work done this week', 'jm timesheet'
  c.example 'Show work done for project', 'jm timesheet --project DEV'
  c.example 'Show work done for projects', 'jm timesheet --project DEV,PROD'
  c.example 'Show work done for keys', 'jm timesheet 12 PROD-15 99 STG-6'

  c.option '--project PROJECTS', Array, 'Limit results to specific projects'

  #c.option '--prev COUNT', Integer, 'Look at previous weeks'
  c.option '--starts_on DAY', String, 'Which day does the week start on'

  c.action do |args, options|
    options.default :starts_on => 'Sat'

    jira = JiraMule::JiraUtils.new
    tempo = JiraMule::Tempo.new

    #Days Of Week
    dows = [:Sun,:Mon,:Tue,:Wed,:Thu,:Fri,:Sat]
    pp options.starts_on
    dayShift = dows.index{|i| options.starts_on.downcase.start_with? i.to_s.downcase}
    workweek = dows.rotate dayShift

    dayTo = Date.today
    dayFrom = dayTo
    while not dayFrom.wday == dayShift do
      dayFrom = dayFrom.prev_day
    end

    # Get keys to get worklogs from
    keys = jira.expandKeys(args)
    if keys.empty? then
      query = %{worklogAuthor = #{jira.username}}
      query << %{ AND worklogDate >= #{dayFrom.iso8601}}

      if options.project and not options.project.empty? then
        query << ' AND '
        query << options.project.map{|p| %{project="#{p}"}}.join(' OR ')
      end

      jira.printVars(:q=>query)
      keys = jira.getIssues(query, ['key']).map{|k| k[:key]}
    end
    jira.printVars(:keys=>keys)

    wls = tempo.workLogs(jira.username, dayFrom.iso8601, dayTo.iso8601)

    # filter out entries not in keys.
    selected = wls.select{|i| keys.include? i.access('issue.key')}

    # build table; each row is a key. each column is hours worked in SSMTWTF
    # multiple passes.
    # 1: build hash by issue, each value is a hash by week day.
    hrows = {}
    selected.each do |isu|
      k = isu.access('issue.key')
      hrows[k] = {} unless hrows.has_key? k
      ds = DateTime.parse(isu[:dateStarted]).to_date
      dow = dows[ds.wday]
      hrows[k][dow] = 0 unless hrows[k].has_key?(dow)
      hrows[k][dow] += isu[:timeSpentSeconds]
    end

    totals = Hash[ *(workweek.map{|i| [i,0]}.flatten) ]
    # 2: reshape into Array or Arrays.
    rows = hrows.to_a.map do |row|
      # row[0] is key, want to keep that.
      # row[1] is a hash we want to sort and flatten.
      row[1] = workweek.map do |d|
        s = row[1][d]
        if s.nil? then
          nil
        else
          totals[d] += s
          ChronicDuration.output(s, :format=>:short)
        end
      end
      row.flatten
    end

    trow = workweek.map do |d|
      s = totals[d]
      if s.nil? then
        nil
      else
        ChronicDuration.output(s, :format=>:short)
      end
    end
    trow.insert(0, 'TOTALS:')

    hdr = workweek.insert(0, :Key)
    table =  Terminal::Table.new do |t|
      t.headings = hdr
      t.rows = rows
      t.add_separator
      t.add_row trow
    end
    puts table
  end
end

#  vim: set sw=2 ts=2 :
