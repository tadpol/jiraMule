#
require 'chronic_duration'
require 'vine'
require 'date'
require 'JiraMule/jiraUtils'

command :logwork do |c|
  c.syntax = 'jm logwork [options] <key> <time spent...>'
  c.summary = 'Log work spent'
  c.description = %{Log time spent on a issue}
  c.option '-m', '--message MSG', String, 'Message to add to work log'
  c.option '--date DATE', String, 'When this work was done'
  c.example 'Log some work done on an issue', %{jm logwork BUG-42 1h 12m}

  c.action do |args, options|
    options.defaults :message => ''
    jira = JiraMule::JiraUtils.new(args, options)

    key = jira.expandKeys(args).shift
    ts = ChronicDuration.parse(args.join(' '))

    unless options.date.nil? then
      options.date = DateTime.parse(options.date)
      if options.date.day_fraction.numerator == 0 then
        # No time component. Need to add timezone...
        offset = -(Time.now.gmt_offset/3600)
        options.date += Rational(offset,24)
      end
    end

    begin
      jira.logWork(key, ts, options.message, options.date)
    rescue JiraUtilsException => e
      pp e.response.body
    end

  end
end
alias_command :lw, :logwork

#  vim: set et sw=2 ts=2 :
