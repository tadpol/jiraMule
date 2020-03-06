require 'vine'
require 'pp'

command :goto do |c|
  c.syntax = 'jm goto [options] [status] [keys]'
  c.summary = 'Move issue to a status; making multiple transitions if needed'
  c.description = %{
Named for the bad command that sometimes there is nothing better to use.

Your issue has a status X, and you need it in Y, and there are multiple steps from
X to Y.  Why would you do something a computer can do better?  Hence goto.

The down side is there is no good way to automatically get mutli-step transitions.
So these need to be added to your config.
}
  c.example 'Move BUG-4 into the In Progress state.', %{jm goto 'In Progress' BUG-4}

  c.action do |args, options|
    jira = JiraMule::JiraUtils.new(args, options)
    to = args.shift

    # keys can be with or without the project prefix.
    keys = jira.expandKeys(args)
    jira.printVars(:to=>to, :keys=>keys)
    raise "No keys to transition" if keys.empty?

    keys.each do |key|
      # First see if we can just go there.
      trans = jira.transitionsFor(key)
      direct = trans.select {|item| jira.fuzzyMatchStatus(item, to) }
      if not direct.empty? then
        # We can just go right there.
        id = direct.first[:id]
        jira.transition(key, id)
        # TODO: deal with required field.
      else

        # where we are.
        #query = "assignee = #{jira.username} AND project = #{jira.project} AND "
        query = "key = #{key}"
        issues = jira.getIssues(query, ["status"])
        #type = issues.first.access('fields.issuetype.name')
        at = issues.first.access('fields.status.name')

        if at == to then
          say "All ready at '#{to}'"
          exit
        end

        # Get the
        transMap = jira.getPath(at, to)
        if transMap.nil? or transMap.empty? then
          say "No transision map found between '#{at}' and '#{to}'"
          y=ask("Would you like to build one? [Yn]")
          exit if y =~ /^n/i
          say_warning "This will make changes to the issue as the map is built."

          start_at = at
          transMap = []
          loop do
            issues = jira.getIssues("key = #{key}", ["status"])
            at = issues.first.access('fields.status.name')
            break if at == to
            trans = jira.transitionsFor(key)
            if trans.length == 1 then
              id = trans.first[:id]
              say "Taking single exit: '#{trans.first[:name]}' (#{trans.first[:id]})"
              transMap << trans.first[:name]
              jira.transition(key, id)
            else
              choose do |menu|
                menu.prompt = "Follow which transition?"
                trans.each do |tr|
                  menu.choice(tr[:name]) do
                    say "Transitioning #{key} to '#{tr[:name]}' (#{tr[:id]})"
                    transMap << tr[:name]
                    jira.transition(key, tr[:id])
                  end
                end
              end
            end
          end
          say "Found the end."
          say " '#{start_at}' to '#{to}' via: #{transMap.join(', ')}"
          y=ask("Record this? [Yn]")
          unless y =~ /^n/ then
            cfgkey = "goto-maps.#{start_at.gsub(/\W+/,'_')}-#{to.gsub(/\W+/,'_')}"
            $cfg.set(cfgkey, transMap.join(', '), :project)
          end
        else

          # Now move thru
          jira.printVars(:key=>key, :tm=>transMap)
          transMap.each do |step|
            trans = jira.transitionsFor(key)
            direct = trans.select {|item| jira.fuzzyMatchStatus(item, step) }
            raise "Broken transition step on #{key} to #{step}" if direct.empty?
            id = direct.first[:id]
            jira.transition(key, id)
            # TODO: deal with required field.
          end
        end

      end
    end
  end
end
alias_command :move, :goto

#  vim: set sw=2 ts=2 :

