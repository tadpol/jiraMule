
command :statuses do |c|
  c.syntax = 'jm statuses <project>'
  c.summary = 'Get all of the status states for a project'
  c.description = 'Get all of the status states for a project'
  c.option '--with_type', "Include and groups statuses with issure type"

  c.action do |args, options|
    options.default :json=> false, :with_type=>false

    jira = JiraMule::JiraUtils.new(args, options)
    prj = args.shift
    ret = jira.statusesFor(prj)

    if options.with_type then
      res = ret.map{|sts| {:name=>sts[:name], :statuses=>(sts[:statuses] or []).map{|sst| sst[:name]}}}
      pp res
    else
      res = ret.map{|sts| (sts[:statuses] or []).map{|sst| sst[:name]}}.flatten.uniq
      if options.json then
        puts res.to_json
      else
        say res.join(', ')
      end
    end

  end
end

#  vim: set sw=2 ts=2 :
