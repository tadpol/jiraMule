require 'chronic_duration'
require 'date'
require 'terminal-table'
require 'vine'
require 'JiraMule/jiraUtils'

command :timesheet do |c|
  c.syntax = 'jm timesheet [options]'
  c.summary = 'Show worklog'
  c.description = %{Show the work done

  }
  c.example 'Show work done this week', 'jm timesheet'
  c.example 'Show work done today', 'jm timesheet --day'
  c.example 'Show work done for project', 'jm timesheet --project DEV'
  c.example 'Show work done for projects', 'jm timesheet --project DEV --project PROD'
  c.example 'Show work done for keys', 'jm timesheet 12 PROD-15 99 STG-6'

  c.option '--project PROJECT', Array, 'Limit results to project'
  c.option '--day'


  c.action do |args, options|

    jira = JiraMule::JiraUtils.new
    tempo = JiraMule::Tempo.new

    # Get keys to get worklogs from
    keys = jira.expandKeys(args)
    if keys.empty? then
      query = %{worklogAuthor = #{jira.username}}
      if options.day then
        query << %{ AND worklogDate > startOfDay()}
      else
        query << %{ AND worklogDate > startOfWeek()}
      end

      if options.project and not options.project.empty? then
        query << ' AND '
        query << options.project.map{|p| %{project="#{p}"}}.join(' OR ')
      end

      jira.printVars(:q=>query)
      keys = jira.getIssues(query, ['key']).map{|k| k[:key]}
    end
    jira.printVars(:keys=>keys)

    dayTo = Date.today
    dayFrom = dayTo
    # XXX Hardcoded assumption that week starts on Saturday.
    unless options.day then
      while not dayFrom.saturday? do
        dayFrom = dayFrom.prev_day
      end
    end

    wls = tempo.workLogs(jira.username, dayFrom.iso8601, dayTo.iso8601)

    # filter out entries not in keys.
    selected = wls.select{|i| keys.include? i.access('issue.key')}

    # build table; each row is a key. each column is hours worked in SSMTWTF
    # multiple passes.
    # 1: build hash by issue, each value is a hash by week day.
    dows = [:Sun,:Mon,:Tue,:Wed,:Thu,:Fri,:Sat]
    hrows = {}
    selected.each do |isu|
      k = isu.access('issue.key')
      hrows[k] = {} unless hrows.has_key? k
      ds = DateTime.parse(isu[:dateStarted]).to_date
      dow = dows[ds.wday]
      hrows[k][dow] = 0 unless hrows[k].has_key?(dow)
      hrows[k][dow] += isu[:timeSpentSeconds]
    end

    workweek = [:Sat,:Sun,:Mon,:Tue,:Wed,:Thu,:Fri]
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
