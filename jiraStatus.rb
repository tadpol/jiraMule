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
List out the task status for including in Release Notes

Usage: jiraTestReady [options]

Options:
  -h --help       This text
  -v --verbose    Verbose
  -t <depth>      Header depth [default: 4]
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

printVars({:project=>project,
		   :userpass=>userpass,
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

# Jira API docs: https://docs.atlassian.com/jira/REST/6.3.6/
#
Net::HTTP.start(@rest2.host, @rest2.port, :use_ssl=>true) do |http|
	def getIssueKeys(http, query)
		request = Net::HTTP::Post.new(@rest2 + 'search')
		request.content_type = 'application/json'
		request.basic_auth(@username, @password)
		request.body = JSON.generate({
			'jql' => query,
			'fields' => [ 'key', 'summary' ]
		})

		verbose "Get keys: #{query}"
		response = http.request(request)
		case response
		when Net::HTTPSuccess
			issues = JSON.parse(response.body)
			keys = issues['issues'].map {|item| item['key'] + ' ' + item.access('fields.summary')}
			return keys
		else
			return []
		end
	end

	hh = '#' * $args['-t'].to_i

	puts "#{hh} Done"
	query ="assignee = #{@username} AND project = #{project} AND status = 'Pending Release'" 
	keys = getIssueKeys(http, query)
	keys.each {|k| puts "- #{k}"}

	puts "#{hh} Testing"
	query ="assignee = #{@username} AND project = #{project} AND status = Testing" 
	keys = getIssueKeys(http, query)
	keys.each {|k| puts "- #{k}"}

	puts "#{hh} In Progress"
	query ="assignee = #{@username} AND project = #{project} AND status = 'In Progress'" 
	keys = getIssueKeys(http, query)
	keys.each {|k| puts "- #{k}"}

	puts "#{hh} To Do"
	query ="assignee = #{@username} AND project = #{project} AND status = Open" 
	keys = getIssueKeys(http, query)
	keys.each {|k| puts "- #{k}"}

end

#  vim: set sw=4 ts=4 :
