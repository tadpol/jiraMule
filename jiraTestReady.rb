#!/usr/bin/ruby
#
require 'uri'
require 'net/http'
require 'json'
require 'date'
require 'yaml'
require 'docopt'
require 'vine'

docs = <<DOCPOT
Little tool for setting the fix version on testable issues

Usage: jiraTestReady [options] [<version>]

Options:
  -h --help       This text
  -n --dry        Don't make changes, just query for issues.
  -v --verbose    Verbose
  -r --reassign   Also reassign to Default
DOCPOT

begin
  $args = Docopt::docopt(docs)
rescue Docopt::Exit => e
  puts e.message
  exit 1
end

class ProjectConfig
	def load()
		cfgFiles = [ '.rpjProject', ENV['HOME'] + '/.rpjProject']
		@cfg = cfgFiles.map do |file|
			result = Hash.new
			if File.exist?(file) 
				File.open(file, 'r') do |fio|
					result = YAML.load(fio)
				end
			end
			result
		end
	end

	def [](key)
		# remove first .
		key = key[1..-1] if key[0] == '.'

		@cfg.each do |acfg|
			v = acfg.access(key)
			return v if !v.nil?
		end
		return nil
	end
end

# Load and merge config files.
$cfg = ProjectConfig.new
$cfg.load()

project=$cfg['.jira.project']
userpass=$cfg['.jira.userpass']
jiraURLBase=$cfg['.jira.url']

def printVars(map)
	$stdout.print("\033[1m=:\033[0m ")
	map.each {|k,v|
		$stdout.print("\033[1m#{k}:\033[0m #{v}  ")
	}
	$stdout.print("\n")
end

def verbose(msg)
	return unless $args['--verbose']
	$stdout.print("\033[1m=#\033[0m ")
	$stdout.print(msg)
	$stdout.print("\n")
end

if not $args['<version>'].nil?
	version = $args['<version>']
else
	# try to guess
	tag = `git for-each-ref --sort=taggerdate --format '%(refname)' refs/tags | tail -1`.chomp
	version = tag.split('/').last

	# ask if ok, and let them type a different one
	print "\033[1m=?\033[0m Enter the version you want to release (#{version}) "
	newver = $stdin.gets.chomp
	version = newver unless newver == ''
end

printVars({:project=>project,
		   :userpass=>userpass,
		   :version=>version,
		   :jira=>jiraURLBase})

# If password is empty, ask for it.
if userpass.include? ':'
	@username, @password = userpass.split(':')
else
	@username = userpass
	# if darwin
	@password = `security 2>&1 >/dev/null find-internet-password -gs "#{jiraURLBase}" -a "#{@username}"`
	@password.strip!
    @password.sub!(/^password: "(.*)"$/, '\1')
end

@rest2 = URI(jiraURLBase + '/rest/api/2/')

Net::HTTP.start(@rest2.host, @rest2.port, :use_ssl=>true) do |http|
	### Create new version
	request = Net::HTTP::Post.new(@rest2 + 'version')
	request.content_type = 'application/json'
	request.basic_auth(@username, @password)
	request.body = JSON.generate({
		'name' => version,
		'archived' => false,
		'released' => false,
		'releaseDate' => DateTime.now.strftime('%Y-%m-%d'),
		'project' => project,
	})

	verbose "Creating #{request.body}"
	if not $args['--dry']
		response = http.request(request)
		case response
		when Net::HTTPSuccess
			vers = JSON.parse(response.body)
		else
			puts "failed on version creation because #{response}"
			puts response.body
			
			exit 1
		end
	end

	def getIssueKeys(http, query)
		request = Net::HTTP::Post.new(@rest2 + 'search')
		request.content_type = 'application/json'
		request.basic_auth(@username, @password)
		request.body = JSON.generate({
			'jql' => query,
			'fields' => [ "key" ]
		})

		verbose "Get keys: #{query}"
		response = http.request(request)
		case response
		when Net::HTTPSuccess
			issues = JSON.parse(response.body)
			keys = issues['issues'].map {|item| item['key'] }
			return keys
		else
			return []
		end
	end

	### Find all unreleased issues
	query ="assignee = #{@username} AND project = #{project} AND status = Testing" 
	keys = getIssueKeys(http, query)
	printVars({:keys=>keys})

	### Mark issues as fixed by version
	updt = { 'fixVersions'=>[{'add'=>{'name'=>version}}] }
	## assign to '-1' to have Jira automatically assign it
	updt['assignee'] = [{'set'=>{'name'=>'-1'}}] if $args['--reassign']
	update = JSON.generate({ 'update' => updt })

	keys.each do |key|
		request = Net::HTTP::Put.new(@rest2 + ('issue/' + key))
		request.content_type = 'application/json'
		request.basic_auth(@username, @password)
		request.body = update

		verbose "Updating key #{key} with #{update}"
		if not $args['--dry']
			response = http.request(request)
			case response
			when Net::HTTPSuccess
			else
				puts "failed on #{key} because #{response}"
			end
		end
	end

end

#  vim: set sw=4 ts=4 :
