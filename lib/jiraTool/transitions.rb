
command :move do |c|
  c.syntax = 'jira move [options] transition [keys]'
  c.summary = 'Move issues into a state.'
  c.description = ''
  c.example 'description', 'command example'
  c.action do |args, options|
		jira = JiraUtils.new(args, options)
		to = args.shift

		# keys can be with or without the project prefix.
		keys = args.map do |k|
			k.match(/([a-zA-Z]+-)?(\d+)/) do |m|
				if m[1].nil? then
					"#{jira.project}-#{m[2]}"
				else
					m[0]
				end
			end
		end.compact
		printVars(:to=>to, :k=>keys)

		# transitions keys.
		jira.transition(keys, to)

		# optinally reassign them

	end
end

#  vim: set sw=2 ts=2 :
