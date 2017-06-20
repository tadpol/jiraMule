
command :query do |c|
  c.syntax = 'jm query [options] query'
  c.summary = 'Get the keys from a jira query'
  c.description = 'Run a JQL query. '
  c.example 'Get all Open issues and dump everything', %{jm query status=Open --all_fields --json}
  c.example 'Show info about an issue', %{jm query --style info BUG-24}
  c.example 'Show info about an issue', %{jm info BUG-24}

  c.option '--style STYLE', String, 'Which output style to use'

  c.option '--[no-]json', 'Output json reply instead of styled output'

  c.option '--fields FIELDS', Array, 'Which fields to return.'
  c.option '--all_fields', 'Return all fields'

  c.option '--[no-]prefix', %{Use the style's query prefix}
  c.option '--[no-]suffix', %{Use the style's query suffix}

  c.option '-d', '--dump', 'Dump the style to STDOUT as yaml'

  c.action do |args, options|
    options.default(
      :json => false,
      :all_fields => false,
      :style => 'basic',
      :prefix => true,
      :suffix => true,
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
    if args.count == 1 and not args.first.include?('=') then
      args = ["key=#{jira.expandKeys([args.first]).first}"]
    end
    opts = {}
    opts[:noprefix] = true unless options.prefix
    opts[:nosuffix] = true unless options.suffix
    args.push(opts) unless opts.empty?
    q = theStyle.build_query(*args)
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
