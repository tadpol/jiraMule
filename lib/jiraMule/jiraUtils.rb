require 'uri'
require 'net/http'
require 'net/http/post/multipart'
require 'json'
require 'date'
require 'pp'
require 'JiraMule/Config'
require 'JiraMule/Passwords'
require 'JiraMule/http'
require 'JiraMule/verbosing'

module JiraMule
    class JiraUtilsException < Exception
        attr_accessor :request, :response
    end

    class JiraUtils
        include Verbose
        include Http

        def initialize(args, options={}, cfg=$cfg)
            @args = args
            @options = options
            @cfg = cfg

            acc = Account.new
            up = acc.loginInfo
            @username = up[:email]
            @password = up[:password]
        end
        attr_reader :username, :password

        def jiraEndPoint
            endPoint()
        end

        def endPoint(path='')
          URI($cfg['net.url'] + '/rest/api/2/' + path.to_s)
        end

        def project
            return @project unless @project.nil?
            @project = @cfg['jira.project']
            @project = @options.project if @options.project # XXX New cfg replaces this.
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
        # Allow for some sloppy matching.
        # +transition+:: The transition hash to match against
        # +couldBe+:: The string from a human to match for
        def fuzzyMatchStatus(transition, couldBe)
            return transition['id'] == couldBe if couldBe =~ /^\d+$/

            # Build a regexp for all sorts of variations.

            # Replace whitespace with a rex for dashes, whitespace, or nospace.
            cb = couldBe.gsub(/\s+/, '[-_\s]*')

            matcher = Regexp.new(cb, Regexp::IGNORECASE)
            verbose "Fuzzing: #{transition['name']} =~ #{cb}"
            return transition['name'] =~ matcher
        end

        ##
        # Lookup a path from one state to another in a map
        # +at+:: The starting state
        # +to+:: The stopping state
        # +map+:: The lookup map to use
        def getPath(at, to, map)
            verbose "In '#{map}', getting path from '#{at}' to '#{to}'"
            transMap = $cfg[".jira.goto.#{map}"] # FIXME config broken
            transMap = $cfg[".jira.goto.*"] if transMap.nil? # FIXME config broken
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

        ##
        # Run a JQL query and get issues with the selected fields
        def getIssues(query, fields=[ 'key', 'summary' ])
            verbose "Get keys: #{query}"
            data = post('search', {:jql=>query, :fields=>fields})
            data[:issues]
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
            verbose "Transitioning key #{key} to #{toID}"
            post('issue/' + key + '/transitions', {:transition=>{:id=>toID}})
        end

        # Get the transitions that a key can move to.
        # +key+:: The issue
        def transitionsFor(key)
            verbose "Fetching transitions for #{key}"
            data = get('issue/' + key + '/transitions')
            data[:transitions]
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
        # +on+:: When this work happened. (default is now)
        def logWork(key, timespent, notes="", on=nil)
            body = {
                :comment => notes,
                :timeSpentSeconds => timespent,
            }
            body[:started] = on.to_time.strftime('%FT%T.%3N%z') unless on.nil?

            verbose "Logging #{timespent} of work to #{key} with note \"#{notes}\""
            post('issue/' + key + '/worklog', body) unless $cfg['tool.dry']
        end

        # Attach a file to an issue.
        # +key+:: The issue to attach to
        # +file+:: Full path to the file to be attached
        # +type+:: MIME type of the fiel data
        # +name+:: Aternate name of file being uploaded
        def attach(key, file, type="application/octect", name=nil)
            if name.nil? then
                name = File.basename(file)
            end

            verbose "Going to upload #{file} to #{key}"

            uri = endPoint('issue/' + key + '/attachments')
            req = Net::HTTP::Post::Multipart.new(uri, 'file'=> UploadIO.new(File.new(file), type, name) )
            set_def_headers(req)
            req['X-Atlassian-Token'] = 'nocheck'

            workit(req) unless $cfg['tool.dry']
        end

    end
end
#  vim: set sw=4 ts=4 :
