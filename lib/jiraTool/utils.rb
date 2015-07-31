require 'uri'
require 'net/http'
require 'json'
require 'date'

def printVars(map)
	$stdout.print("\033[1m=:\033[0m ")
	map.each {|k,v|
		$stdout.print("\033[1m#{k}:\033[0m #{v}  ")
	}
	$stdout.print("\n")
end

def verbose(msg)
	#return unless $args['--verbose']
	$stdout.print("\033[1m=#\033[0m ")
	$stdout.print(msg)
	$stdout.print("\n")
end

def getIssueKeys(query)
	r = $cfg.jiraEndPoint
	Net::HTTP.start(r.host, r.port, :use_ssl=>true) do |http|
		request = Net::HTTP::Post.new(r + 'search')
		request.content_type = 'application/json'
		request.basic_auth($cfg.username, $cfg.password)
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
end


