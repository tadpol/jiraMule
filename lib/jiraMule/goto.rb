require 'vine'
require 'pp'

command :goto do |c|
  c.syntax = 'jm goto [options] [status] [keys]'
  c.summary = 'Move issue to a status; making multiple transitions if needed'
  c.description = %{
	Named for the bad command that sometime there is nothing better to use.

	Your issue has a status X, and you need it in Y, and there are multiple steps from
	X to Y.  Why would you do something a computer can do better?  Hence goto.

	The down side is there is no good way to automatically get mutli-step transitions.
	So these need to be added to your config.
	}
  c.example 'Move BUG-4 into the In Progress state.', %{jm goto 'In Progress' BUG-4}
	c.option '-m', '--map MAPNAME', String, 'Which workflow map to use'
  c.action do |args, options|
		options.default :m=>'PSStandard'
		jira = JiraUtils.new(args, options)
		to = args.shift

		# keys can be with or without the project prefix.
		keys = jira.expandKeys(args)
		printVars(:to=>to, :keys=>keys)
		return if keys.empty?

		keys.each do |key|
			# First see if we can just go there.
			trans = jira.transitionsFor(key)
			direct = trans.select {|item| jira.fuzzyMatchStatus(item, to) }
			if not direct.empty? then
				# We can just go right there.
				id = direct.first['id']
				jira.transition(key, id)
				# TODO: deal with required field.
			else

				# where we are.
				query = "assignee = #{jira.username} AND project = #{jira.project} AND "
				query << "key = #{key}"
				issues = jira.getIssues(query, ["status"])
				type = issues.first.access('fields.issuetype.name')
				at = issues.first.access('fields.status.name')

				# Get the 
				transMap = getPath(at, to, options.map)

				# Now move thru
				transMap.each do |step|
					trans = jira.transitionsFor(key)
					direct = trans.select {|item| jira.fuzzyMatchStatus(item, step) }
					raise "Broken transition step on #{key} to #{step}" if direct.empty?
					id = direct.first['id']
					jira.transition(key, id)
					# TODO: deal with required field.
				end

			end
		end
	end
end
alias_command :move, :goto

command :mapGoto do |c|
  c.syntax = 'jm mapGoto [options]'
  c.summary = 'Attempt to build a goto map'
  c.description = %{
	This command is incomplete.  The goal here is to auto-build the transision maps
	for multi-step gotos.

	Right now it is just dumping stuff.

	}
  c.action do |args, options|
		jira = JiraUtils.new(args, options)

		# Get all of the states that issues can be in.
		# Try to find an actual issue in each state, and load the next transitions from
		# it.
		#
		types = jira.statusesFor(jira.project)
		
		# There is only one workflow for all types it seems.

		# We just need the names, so we'll merge down.
		statusNames = {}

		types.each do |type|
			statuses = type['statuses']
			next if statuses.nil?
			next if statuses.empty?
			statuses.each {|status| statusNames[ status['name'] ] = 1}
		end

		statusNames.each_key do |status|
			puts "    #{status}"
			query = %{project = #{jira.project} AND status = "#{status}"}
			issues = jira.getIssues(query, ["key"])
			if issues.empty? then
				#?
			else
				key = issues.first['key']
				# get transisitons.
				trans = jira.transitionsFor(key)
				trans.each {|tr| puts "      -> #{tr['name']} [#{tr['id']}]"}
			end
		end

	end
end

def getPath(at, to, map)
	transMap = $cfg[".jira.goto.#{map}"]
	transMap = defaultMaps().access("jira.goto.#{map}") if transMap.nil?
	transMap = $cfg[".jira.goto.*"] if transMap.nil?
	transMap = defaultMaps().access("jira.goto.*") if transMap.nil?
	raise "No maps for #{map}" if transMap.nil?
	
	starts = transMap.keys.select {|k| k == at}
	starts = ['*'] if starts.empty? and transMap.has_key? '*'
	raise "No starting point for #{at}" if starts.nil? || starts.empty?

	sets = transMap[starts.first]
	stops = sets.keys.select {|k| k == to}
	stops = ['*'] if stops.empty? and sets.has_key? '*'
	raise "No stopping point for #{to}" if stops.nil? || stops.empty?
	
	return sets[stops.first] + [to]
end

# These are based on the workflows we have at my work.
def defaultMaps()
	return {
		'jira'=>{
			'goto'=>{
				'PSBasic'=>{
					'Open'=>{
						"Dev Ready"=> ["Needs BA"],
						"In Development"=> ["Needs BA", "Dev Ready"],
						"Code Review"=> ["Needs BA", "Dev Ready", "In Development"],
						"QA"=> ["Needs BA", "Dev Ready", "In Development", "Code Review"],
						"QA - Bug Found"=> ["Needs BA", "Dev Ready", "In Development", "Code Review", "QA"],
						"Dev/QA Complete"=> ["Needs BA", "Dev Ready", "In Development", "Code Review", "QA"],
					},
					"Needs BA"=>{
						"In Development"=> ["Dev Ready"],
						"Code Review"=> ["Dev Ready", "In Development"],
						"QA"=> ["Dev Ready", "In Development", "Code Review"],
						"QA - Bug Found"=> ["Dev Ready", "In Development", "Code Review", "QA"],
						"Dev/QA Complete"=> ["Dev Ready", "In Development", "Code Review", "QA"],
					},
					"Dev Ready"=>{
						"Code Review"=> ["In Development"],
						"QA"=> ["In Development", "Code Review"],
						"QA - Bug Found"=> ["In Development", "Code Review", "QA"],
						"Dev/QA Complete"=> ["In Development", "Code Review", "QA"],
					},
					"In Development"=>{
						"Dev Ready"=> ["Code Review"],
						"QA"=> ["Code Review"],
						"QA - Bug Found"=> ["Code Review", "QA"],
						"Dev/QA Complete"=> ["Code Review", "QA"],
					},
					"Code Review"=>{
						"In Development"=> ["Dev Ready"],
						"QA - Bug Found"=> ["QA"],
						"Dev/QA Complete"=> ["QA"],
					}
				},
				"PSStandard"=>{
					# If there is a matching named state, that will always be preferred to the
					# catchall state.
					'Waiting Estimation Approval' => {
						'In Progress' => ['Open'],
						'*'=>['Blocked']
					},
					'*'=>{
						'*'=>['Blocked']
					}
				},
				"PSStaging"=>{
					'*'=>{'*'=>['Blocked']}
				}
			}
		}
	}
end

#  vim: set sw=2 ts=2 :

