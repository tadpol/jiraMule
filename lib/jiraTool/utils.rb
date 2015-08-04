require 'uri'
require 'net/http'
require 'json'
require 'date'

# ??? require 'jiraby' ???

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
		@jiraEndPoint = URI(@cfg['.jira.url'] + '/rest/api/2/')
		return @jiraEndPoint
	end

	def getIssues(query)
		r = jiraEndPoint()
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Post.new(r + 'search')
			request.content_type = 'application/json'
			request.basic_auth(username(), password())
			request.body = JSON.generate({
				'jql' => query,
				'fields' => [ 'key', 'summary' ]
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

	def checkUser(user, keyMatch=true)
		# make sure #user is an actual user in the system.
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
					puts "failed on version creation because #{response}"
					puts response.body

					exit 1
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
						puts "failed on #{key} because #{response}"
					end
				end
			end
		end
	end

	def transition(keys, to)
		r = jiraEndPoint
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			# *sigh* Need to transition by ID, buts what's the ID? So look that up
			request = Net::HTTP::Get.new(r + ('issue/' + keys.first + '/transitions'))
			request.content_type = 'application/json'
			request.basic_auth(username, password)
			verbose "Fetching transition ID for #{to}"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				trans = JSON.parse(response.body)
				closed = trans['transitions'].select {|item| item['name'] == to }
			else
				puts "failed because"
				exit 1 # FIXME: return or throw instead
			end

			if closed.empty?
				puts "Cannot find Transition to Closed!!!!"
				exit 2 # FIXME: return or throw instead
			end

			printVars({:closedID=>closed[0]['id']})

			update = JSON.generate({'transition'=>{'id'=> closed[0]['id'] }})
			keys.each do |key|
				request = Net::HTTP::Post.new(@rest2 + ('issue/' + key + '/transitions'))
				request.content_type = 'application/json'
				request.basic_auth(username, password)
				request.body = update

				verbose "Updating key #{key} with #{update}"
				if not @options.dry
					response = http.request(request)
					case response
					when Net::HTTPSuccess
					else
						puts "failed on #{key} because #{response}"
					end
				end
			end
		end
	end
end

class GitUtils

	def self.getVersion
		tag = `git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags | head -1`.chomp
		return tag.split('/').last
	end
end

#  vim: set sw=4 ts=4 :
