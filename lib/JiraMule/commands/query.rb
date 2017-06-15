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

  c.option '-d', '--dump', 'Dump the style to STDOUT as yaml'

  c.action do |args, options|
    options.default(
      :json => false,
      :all_fields => false,
      :style => 'basic',
      :raw=> true
    )

    theStyle = JiraMule::Style.fetch(options.style).dup
    if theStyle.nil? then
      say_error "No style \"#{options.style}\""
      say_error "Try one of: #{JiraMule::Style.list.join(', ')}"
      exit 2
    end
    #### look for command line overrides
    fields = theStyle.fields
    fields = options.fields if options.fields
    fields = [] if options.all_fields

    if options.dump then
      puts theStyle.to_yaml
      exit 0
    end

    jira = JiraMule::JiraUtils.new(args, options)
    # TODO: Grab {prefix,suffix,default}_query from Style
#    args.unshift("assignee = #{jira.username} AND") unless options.raw
#    args.unshift("project = #{jira.project} AND") unless options.raw
    if args.count == 1 and not args.first.include?('=') then
      q = "key=#{jira.expandKeys([args.first]).first}"
    else
      q = args.join(' ')
    end
    issues = jira.getIssues(q, fields)

    if options.json then
      puts JSON.dump(issues)
    else
      puts theStyle.apply(issues)
    end
  end
end
alias_command :q, :query
alias_command :info, :query, '--style', 'info'

#  vim: set sw=2 ts=2 :
