require 'uri'
require 'net/http'
require 'net/http/post/multipart'
require 'json'
require 'date'
require 'pp'

def printVars(map)
	$stdout.print("\033[1m=:\033[0m ")
	map.each {|k,v|
		$stdout.print("\033[1m#{k}:\033[0m #{v}  ")
	}
	$stdout.print("\n")
end

def printErr(msg)
	$stdout.print("\033[1m=!\033[0m ")
	$stdout.print(msg)
	$stdout.print("\n")
end

class JiraUtilsException < Exception
	attr_accessor :request, :response
end

class JiraUtils

	def initialize(args, options={}, cfg=$cfg)
		@args = args
		@options = options
		@cfg = cfg
	end

	def verbose(msg)
		return unless @options.verbose
		$stdout.print("\033[1m=#\033[0m ")
		$stdout.print(msg)
		$stdout.print("\n")
	end

	def username
		return @username unless @username.nil?
		userpass = @cfg['.jira.userpass']
		if userpass.include? ':'
			@username, @password = userpass.split(':')
		else
			@username = userpass
			# if darwin
			@password = `security 2>&1 >/dev/null find-internet-password -gs "#{@cfg['.jira.url']}" -a "#{@username}"`
			@password.strip!
			@password.sub!(/^password: "(.*)"$/, '\1')
		end
		return @username
	end
	def password
		return @password unless @username.nil?
		userpass = @cfg['.jira.userpass']
		if userpass.include? ':'
			@username, @password = userpass.split(':')
		else
			@username = userpass
			# if darwin
			@password = `security 2>&1 >/dev/null find-internet-password -gs "#{@cfg['.jira.url']}" -a "#{@username}"`
			@password.strip!
			@password.sub!(/^password: "(.*)"$/, '\1')
		end
		return @password
	end

	def jiraEndPoint
		return @jiraEndPoint unless @jiraEndPoint.nil?
		base = @cfg['.jira.url']
		base = @options.url if @options.url
		@jiraEndPoint = URI(@cfg['.jira.url'] + '/rest/api/2/')
		return @jiraEndPoint
	end

	def project
		return @project unless @project.nil?
		@project = @cfg['.jira.project']
		@project = @options.project if @options.project
		return @project
	end

	##
	# Given an array of issues keys that may or may not have the project prefixed
	# Return an array with the project prefixed.
	#
	# So on project APP, from %w{1 56 BUG-78} you get %w{APP-1 APP-56 BUG-78}
	def expandKeys(keys)
		return keys.map do |k|
			k.match(/([a-zA-Z]+-)?(\d+)/) do |m|
				if m[1].nil? then
					"#{project}-#{m[2]}"
				else
					m[0]
				end
			end
		end.compact
	end

	##
	# Run a JQL query and get issues with the selected fields
	def getIssues(query, fields=[ 'key', 'summary' ])
		r = jiraEndPoint()
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Post.new(r + 'search')
			request.content_type = 'application/json'
			request.basic_auth(username(), password())
			request.body = JSON.generate({
				'jql' => query,
				'fields' => fields
			})

			verbose "Get keys: #{query}"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				issues = JSON.parse(response.body)
				#return issues
				return issues['issues']

			else
				return []
			end
		end
	end

	##
	# make sure #user is an actual user in the system.
	def checkUser(user, keyMatch=true)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			r = r + 'user/search' 
			r.query = "username=#{user}"
			request = Net::HTTP::Get.new(r)
			request.basic_auth(username(), password())

			verbose "Get user: #{r}"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				users = JSON.parse(response.body)
				userKeys = users.map{|i| i['key']}
				return [user] if keyMatch and userKeys.index(user)
				return userKeys

			else
				puts response
				return []
			end
		end
	end

	def createVersion(project, version)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			### Create new version
			request = Net::HTTP::Post.new(r + 'version')
			request.content_type = 'application/json'
			request.basic_auth(username(), password())
			request.body = JSON.generate({
				'name' => version,
				'archived' => false,
				'released' => true,
				'releaseDate' => DateTime.now.strftime('%Y-%m-%d'),
				'project' => project,
			})

			verbose "Creating #{request.body}"
			if not @options.dry
				response = http.request(request)
				case response
				when Net::HTTPSuccess
					vers = JSON.parse(response.body)
					if !vers['released']
						# Sometimes setting released on create doesn't work.
						# So modify it.
						request = Net::HTTP::Put.new(r + ('version/' + vers['id'])) 
						request.content_type = 'application/json'
						request.basic_auth(username(), password())
						request.body = JSON.generate({ 'released' => true })
						response = http.request(request)

					end
				else
					ex = JiraUtilsException.new("Failed to create version #{version} in project #{project}")
					ex.request = request
					ex.response = response
					raise ex
				end
			end
		end
	end

	def updateKeys(keys, update)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			keys.each do |key|
				request = Net::HTTP::Put.new(r + ('issue/' + key))
				request.content_type = 'application/json'
				request.basic_auth(username(), password())
				request.body = JSON.generate({ 'update' => update }) 

				verbose "Updating key #{key} with #{update}"
				if not @options.dry
					response = http.request(request)
					case response
					when Net::HTTPSuccess
					else
						ex = JiraUtilsException.new("Failed to update #{key} with #{update}")
						ex.request = request
						ex.response = response
						raise ex
					end
				end
			end
		end
	end

	# Transition key into a new status
	# +key+:: The key to transition
	# +toID+:: The ID of the transition to make
	def transition(key, toID)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			update = JSON.generate({'transition'=>{'id'=> toID }})
			request = Net::HTTP::Post.new(r + ('issue/' + key + '/transitions'))
			request.content_type = 'application/json'
			request.basic_auth(username, password)
			request.body = update

			verbose "Transitioning key #{key} to #{toID}"
			if not @options.dry
				response = http.request(request)
				case response
				when Net::HTTPSuccess
				else
					ex = JiraUtilsException.new("Failed to transition #{key} to #{toID}")
					ex.request = request
					ex.response = response
					raise ex
				end
			end
		end
	end

	# Get the transitions that a key can move to.
	# +key+:: The issue 
	def transitionsFor(key)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			# *sigh* Need to transition by ID, buts what's the ID? So look that up
			request = Net::HTTP::Get.new(r + ('issue/' + key + '/transitions'))
			request.content_type = 'application/json'
			request.basic_auth(username, password)
			verbose "Fetching transitions for #{key}"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				trans = JSON.parse(response.body)
				closed = trans['transitions']
			else
				ex = JiraUtilsException.new("Failed to get transitions for #{key}")
				ex.request = request
				ex.response = response
				raise ex
			end
			return closed
		end
	end

	# Get the status for a project
	# +project+:: The project to fetch status from
	def statusesFor(project)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Get.new(r + ('project/' + project + '/statuses'))
			request.content_type = 'application/json'
			request.basic_auth(username, password)
			verbose "Fetching statuses for #{project}"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				statuses = JSON.parse(response.body)
			else
				ex = JiraUtilsException.new("Failed to get statuses for #{project}")
				ex.request = request
				ex.response = response
				raise ex
			end
			return statuses
		end
	end


	# Log a work entry to Jira
	# +key+:: The issue to log work on
	# +timespend+:: The time spent in seconds
	# +notes+:: Any notes to add.
	def logWork(key, timespent, notes="")
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Post.new(r + ('issue/' + key + '/worklog'))
			request.content_type = 'application/json'
			request.basic_auth(username(), password())
			request.body = JSON.generate({
				:comment => notes,
				:timeSpentSeconds => timespent
			}) 

			verbose "Logging #{timespent} of work to #{key} with note \"#{notes}\""
			return if @options.dry
			response = http.request(request)
			case response
			when Net::HTTPSuccess
			else
				ex = JiraUtilsException.new("Failed to log work on #{key}")
				ex.request = request
				ex.response = response
				raise ex
			end
		end
	end

	# Attach a file to an issue.
	# +key+:: The issue to attach to
	# +file+:: Full path to the file to be attached
	# +type+:: MIME type of the fiel data
	# +name+:: Aternate name of file being uploaded
	def attach(key, file, type="application/octect", name=nil)
		r = jiraEndPoint
		if name.nil? then
			name = File.basename(file)
		end
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			path = r + ('issue/' + key + '/attachments')
			request = Net::HTTP::Post::Multipart.new(path,
													 'file'=> UploadIO.new(File.new(file), type, name) )
			#request.content_type = 'application/json'
			request.basic_auth(username, password)
			request['X-Atlassian-Token'] = 'nocheck'

			verbose "Going to upload #{file} to #{key}"
			if not @options.dry
				response = http.request(request)
				case response
				when Net::HTTPSuccess
				else
					ex = JiraUtilsException.new("Failed to POST #{file} to #{key}")
					ex.request = request
					ex.response = response
					raise ex
				end
			end
		end
	end

end

#  vim: set sw=4 ts=4 :
