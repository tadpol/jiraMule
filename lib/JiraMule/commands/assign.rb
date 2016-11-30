require 'JiraMule/jiraUtils'

command :assign do |c|
  c.syntax = 'jm assign [options] <to user> <keys...> '
  c.summary = 'Assign keys to another user'

  c.action do |args, options|

    jira = JiraMule::JiraUtils.new(args, options)

    muser = args.shift
    if muser == '-1' or muser =~ /^:de/ then
      # assign to default
      to = '-1'
    else
      to = jira.checkUser(muser)
      if to.count > 1 then
        say "Username '#{muser}' is ambigious."
        say "Could be: #{to.join(' ')}"
        exit 4
      elsif to.empty? then
        say "No such user: '#{muser}'"
        exit 4
      end
      to = to.first
    end

    # keys can be with or without the project prefix.
    keys = jira.expandKeys(args)

    jira.printVars(:key=>keys, :to=>to)

    jira.assignTo(keys, to)

  end
end

#  vim: set sw=2 ts=2 :
