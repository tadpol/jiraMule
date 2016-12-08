require 'JiraMule/jiraUtils'

command :links do |c|
  c.syntax = %{jm links}
  c.summary = %{Show all remote links}

  c.action do |args, options|
    jira = JiraMule::JiraUtils.new(args, options)
    keys = jira.expandKeys(args)
    keys.each do |key|
      jira.remote_links(key).each do |link|
        obj = link[:object]
        unless obj.nil? then
          say "- #{obj[:title]}"
          say "  #{obj[:url]}"
        end
      end
    end
  end
end

command :addLink do |c|
  c.syntax = %{jm addLink <key> <url> <title>}
  c.summary = %{Add a remote link to an issue}
  c.action do |args, options|
    jira = JiraMule::JiraUtils.new(args, options)
    key = jira.expandKeys(arg[0])
    url = arg[1]
    title = arg[2]
    if url.nil? then
      say_error "Missing URL"
    elsif title.nil? then
      say_error "Missing Title"
    else
      jira.linkTo(key, url, title)
    end
  end
end
alias_command :link, :addLink

#  vim: set ai et sw=2 ts=2 :
