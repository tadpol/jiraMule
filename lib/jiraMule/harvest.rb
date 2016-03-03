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
		@username = @cfg['.harvest.user']
		# if darwin
		@password = `security 2>&1 >/dev/null find-internet-password -gs "#{@cfg['.harvest.url']}" -a "#{@username}"`
		@password.strip!
		@password.sub!(/^password: "(.*)"$/, '\1')
		return @username
	end
	def password
		return @password unless @username.nil?
		@username = @cfg['.harvest.user']
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
			request['Accept'] = 'application/json'
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

	def projectIDfromName(name)
		projects = getProjectsAndTasks()
		matches = projects.select do |prj| 
			return false unless prj.is_a? Hash
			return false unless prj.has_key? 'id'
			return false unless prj.has_key? 'name'
			return prj['name'] == name if name.is_a? String
			return prj['name'] =~ name if name.is_a? Regexp
			return false
		end
		return nil if matches.empty?
		prj = matches.first
		prj['id']
	end

	def projectIDfromCode(code)
		projects = getProjectsAndTasks()
		matches = projects.select do |prj| 
			return false unless prj.is_a? Hash
			return false unless prj.has_key? 'id'
			return false unless prj.has_key? 'code'
			return prj['code'] == name if name.is_a? String
			return prj['code'] =~ name if name.is_a? Regexp
			return false
		end
		return nil if matches.empty?
		prj = matches.first
		prj['id']
	end

	def taskIDfromProjectAndName(project=self.project, task=self.task)
		verbose %{Going to find from "#{project}" and "#{task}"}
		projects = getProjectsAndTasks()
		pp projects
		matches = projects.select do |prj| 
			return false unless prj.is_a? Hash
			return false unless prj.has_key? 'id'
			return false unless prj.has_key? 'code'
			return false unless prj.has_key? 'name'
			return false unless prj.has_key? 'tasks'
			return prj['code'] == project if project.is_a? String
			return prj['code'] =~ project if project.is_a? Regexp
			return prj['name'] == project if project.is_a? String
			return prj['name'] =~ project if project.is_a? Regexp
			return false
		end
		return [nil,nil] if matches.empty?

		# have matching projects.  Now filter down to 
		verbose "Multiple projects(#{matches.length}) found, using first" if matches.length > 1
		prj = matches.first
		matches = prj['tasks'].select do |tsk|
			return false unless tsk.is_a? Hash
			return false unless tsk.has_key? 'id'
			return false unless tsk.has_key? 'name'
			return tsk['name'] == task if task.is_a? String
			return tsk['name'] =~ task if task.is_a? Regexp
			return false
		end
		return [prj['id'], nil] if matches.empty?
		verbose "Multiple tasks(#{matches.length}) found, using first" if matches.length > 1
		tsk = matches.first
		return [prj['id'], tsk['id']]
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
