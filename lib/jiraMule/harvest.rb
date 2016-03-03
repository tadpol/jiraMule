require 'uri'
require 'net/http'
require 'json'
require 'date'
require 'pp'

class HarvestUtilsException < Exception
	attr_accessor :request, :response
end

class HarvestUtils

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
		userpass = @cfg['.harvest.user']
		@username = userpass
		# if darwin
		@password = `security 2>&1 >/dev/null find-internet-password -gs "#{@cfg['.harvest.url']}" -a "#{@username}"`
		@password.strip!
		@password.sub!(/^password: "(.*)"$/, '\1')
		return @username
	end
	def password
		return @password unless @username.nil?
		userpass = @cfg['.jira.userpass']
		@username = userpass
		# if darwin
		@password = `security 2>&1 >/dev/null find-internet-password -gs "#{@cfg['.harvest.url']}" -a "#{@username}"`
		@password.strip!
		@password.sub!(/^password: "(.*)"$/, '\1')
		return @password
	end

	def endPoint
		return @endPoint unless @endPoint.nil?
		base = @cfg['.harvest.url']
		base = @options.url if @options.url
		@endPoint = URI(@cfg['.harvest.url'])
		return @endPoint
	end

	def project
		return @project unless @project.nil?
		@project = @cfg['.harvest.project']
		@project = @options.project if @options.project
		return @project
	end

	def task
		return @task unless @task.nil?
		@task = @cfg['.harvest.task']
		@task = @options.task if @options.task
		return @task
	end


	def getProjectsAndTasks()
		r = endPoint()
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Post.new(r + 'daily')
			request.content_type = 'application/json'
			request.basic_auth(username(), password())

			verbose "Getting Projects and Tasks"
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				daily = JSON.parse(response.body)
				return daily['projects']
			else
				return []
			end

		end
	end


	# Log a work entry to Harvest
	# +project+:: The project ID
	# +task+:: The task ID
	# +timespend+:: The time spent in seconds
	# +notes+:: Any notes to add.
	def logWork(project, task, timespent, notes)
		r = endPoint()
		Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
			request = Net::HTTP::Post.new(r + 'daily/add')
			request.content_type = 'application/json'
			request.basic_auth(username(), password())
			request.body = JSON.generate({
				:notes => notes,
				:project_id => project,
				:task_id => task,
				:hours => (timespent / 3600.0)
			})
			verbose "Getting Projects and Tasks"
			return if @options.dry
			response = http.request(request)
			case response
			when Net::HTTPSuccess
				daily = JSON.parse(response.body)
				return daily
			else
				ex = HarvestUtilsException.new("Failed to log work on #{project}:#{task}")
				ex.request = request
				ex.response = response
				raise ex
			end
		end
	end

end

#  vim: set sw=4 ts=4 :
