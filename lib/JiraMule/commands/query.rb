require 'terminal-table'
require 'mustache'

command :query do |c|
  c.syntax = 'jm query [options] query'
  c.summary = 'Get the keys from a jira query'
  c.description = 'Run a JQL query. '
  c.example 'Get Open issues and dump everything', %{jm query status=Open --all_fields --json}
  c.example 'Get All Open issues and dump everything', %{jm query --raw status=Open --all_fields --json}

  c.option '--style STYLE', String, 'Which output style to use'

  c.option '--[no-]raw', 'Do not prefix query with project and assignee'
  c.option '--[no-]json', 'Output json reply instead of summary'

  c.option '--fields FIELDS', Array, 'Which fields to return.'
  c.option '--all_fields', 'Return all fields'
  #c.option '--format STYLE', String, 'Format for keys'

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
        :format => %{{{key}} {{summary}}},
      },
      :info => {
        :fields => [:key, :description, :assignee, :reporter, :priority, :issuetype,
                    :status, :resolution, :votes, :watches],
        :format => %{{{key}}
   Reporter: {{reporter.displayName}}
   Assignee: {{assignee.displayName}}
       Type: {{issuetype.name}} ({{priority.name}})
     Status: {{status.name}} (Resolution: {{resolution.name}})
    Watches: {{watches.watchCount}}  Votes: {{votes.votes}}
Description: {{description}}
        }
      },
    }

    theStyle = allOfThem[options.style.to_sym]
    theStyle[:fields] = options.fields if options.fields

    jira = JiraMule::JiraUtils.new(args, options)
    args.unshift("assignee = #{jira.username} AND") unless options.raw
    args.unshift("project = #{jira.project} AND") unless options.raw
    if args.count == 1 and not args.first.include?('=') then
      q = "key=#{args.first}"
    else
      q = args.join(' ')
    end
    if options.all_fields then
      issues = jira.getIssues(q, [])
    else
      issues = jira.getIssues(q, theStyle[:fields])
    end
    if options.json then
      puts JSON.dump(issues)
    else

      format = theStyle[:format]
      keys = issues.map do |issue|
        Mustache.render(format, issue.merge(issue[:fields]))
      end
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
