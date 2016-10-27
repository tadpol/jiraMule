require 'vine'
require 'pp'
require 'JiraMule/jiraUtils'

command :next do |c|
  c.syntax = 'jm next [options] [keys]'
  c.summary = 'Move issue to the next state'
  c.description = %{
  Move to the next state. For states with multiple exits, use the 'preferred' one.
  }
  c.example 'Move BUG-4 into the next state.', %{jm next BUG-4}
  c.option '--[no-]save-next', %{Save this }

  c.action do |args, options|
    jira = JiraMule::JiraUtils.new(args, options)

    # keys can be with or without the project prefix.
    keys = jira.expandKeys(args)
    jira.printVars(:keys=>keys)
    return if keys.empty?

    keys.each do |key|
      # First see if there is a single exit. If so, just do that.
      trans = jira.transitionsFor(key)
      pp trans
      exit
      if trans.length == 1 then
        id = trans.first[:id]
        jira.verbose "Taking single exit: '#{trans.first[:name]}'"
        jira.transition(key, id)

      else
        # If more than one:

        # Need to know the name of the state we are currently in
        query = "assignee = #{jira.username} AND project = #{jira.project} AND "
        query << "key = #{key}"
        issues = jira.getIssues(query, ["status"])
        at = issues.first.access('fields.status.name')

        # If a preferred transition is set, use that
        nxt = $cfg["next-preferred.#{at}"]
        unless nxt.nil? then
          direct = trans.select {|item| jira.fuzzyMatchStatus(item, nxt) }
          unless direct.empty? then
            id = direct.first[:id]
            jira.verbose "Transitioning #{key} to #{direct.first['name']} (#{id})"
            jira.transition(key, id)
            return
          end
        end

        # Filter ignored transitions; If only one left, goto it.
        skiplist = $cfg['next.ignore'] || []
        check = trans.reject{|t| skiplist.include? t[:name] }
        if check.length == 1 then
          id = check.first['id']
          jira.verbose "Taking filtered single exit: '#{check.first[:name]}'"
          jira.transition(key, id)
        end

        # Otherwise, ask which transition to use.
        # - save that as preferred
        # - goto it.
        choose do |menu|
          menu.prompt = "Follow which transition?"
          trans.each do |tr|
            menu.choice(tr[:name]) do
              # TODO save
              jira.verbose "Transitioning #{key} to #{tr[:name]} (#{tr[:id]})"
              jira.transition(key, tr[:id])
            end
          end
        end

      end

    end #keys.each
  end
end


#  vim: set sw=2 ts=2 :

