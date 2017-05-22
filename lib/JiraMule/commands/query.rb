require 'terminal-table'
require 'mustache'

command :query do |c|
  c.syntax = 'jm query [options] query'
  c.summary = 'Get the keys from a jira query'
  c.description = 'Run a JQL query. '
  c.example 'Get Open issues and dump everything', %{jm query status=Open --all_fields --json}
  c.example 'Get All Open issues and dump everything', %{jm query --raw status=Open --all_fields --json}
  c.example 'Show info about an issue', %{jm query --style info BUG-24}
  c.example 'Show info about an issue', %{jm info BUG-24}

  c.option '--style STYLE', String, 'Which output style to use'

  c.option '--[no-]raw', 'Do not prefix query with project and assignee'
  c.option '--[no-]json', 'Output json reply instead of styled output'

  c.option '--fields FIELDS', Array, 'Which fields to return.'
  c.option '--all_fields', 'Return all fields'

  c.action do |args, options|
    options.default(
      :json => false,
      :all_fields => false,
      :style => 'basic',
      :raw=> true
    )

    allOfThem = {
      :basic => {
        :fields => [:key, :summary],
        :format_type => :strings,
        :format => %{{{key}} {{summary}}},
      },
      :info => {
        :fields => [:key, :summary, :description, :assignee, :reporter, :priority,
                    :issuetype, :status, :resolution, :votes, :watches],
        :format_type => :strings,
        :format => %{{{key}}
    Summary: {{summary}}
   Reporter: {{reporter.displayName}}
   Assignee: {{assignee.displayName}}
       Type: {{issuetype.name}} ({{priority.name}})
     Status: {{status.name}} (Resolution: {{resolution.name}})
    Watches: {{watches.watchCount}}  Votes: {{votes.votes}}
Description: {{description}}
        }
      },
      :test_table => {
        :fields => [:key, :assignee],
        :format_type => :table_columns,
        :header => [],
        :format => [%{{{key}}}, %{{{assignee.displayName}}}]
      },
      :prgs => {
        :fields => [:key, :workratio, :aggregatetimespent, :duedate,
                    :aggregatetimeoriginalestimate],
        :format_type => :table_rows, # :table_columns
        :header => [:key, :workratio, :aggregatetimespent, :duedate,
                    :aggregatetimeoriginalestimate],
        :format => [%{{{key}}}, %{{{workratio}}},
                    %{{{aggregatetimespent}}},
                    %{{{duedate}}},
                    %{{{aggregatetimeoriginalestimate}}},
        ]
      },
    }

    theStyle = allOfThem[options.style.to_sym]
    if theStyle.nil? then
      say_error "No style \"#{options.style}\""
      exit 2
    end
    #### look for command line overrides
    theStyle[:fields] = options.fields if options.fields

    jira = JiraMule::JiraUtils.new(args, options)
    args.unshift("assignee = #{jira.username} AND") unless options.raw
    args.unshift("project = #{jira.project} AND") unless options.raw
    if args.count == 1 and not args.first.include?('=') then
      q = "key=#{jira.expandKeys([args.first]).first}"
    else
      q = args.join(' ')
    end
    if options.all_fields then
      issues = jira.getIssues(q, [])
    else
      issues = jira.getIssues(q, theStyle[:fields])
    end

    format_type = (theStyle[:format_type] or :strings).to_sym

    if options.json then
      puts JSON.dump(issues)
    elsif format_type == :strings then
      format = theStyle[:format]
      keys = issues.map do |issue|
        Mustache.render(format, issue.merge(issue[:fields]))
      end
      keys.each {|k| puts k}

    elsif [:table, :table_rows, :table_columns].include? format_type then
      format = theStyle[:format] or []
      format = [format] unless format.kind_of? Array
      rows = issues.map do |issue|
        format.map do |col|
          Mustache.render(col, issue.merge(issue[:fields]))
        end
      end
      if format_type == :table_columns then
        rows = rows.transpose
      end
      puts Terminal::Table.new :headings => (theStyle[:header] or []), :rows=>rows
    end

  end
end
alias_command :q, :query
alias_command :info, :query, '--style', 'info'

#  vim: set sw=2 ts=2 :
