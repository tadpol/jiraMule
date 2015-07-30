require 'yaml'
require 'vine'

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


	def username()
		return @username unless @username.nil?
		userpass = self['.jira.userpass']
		if userpass.include? ':'
			@username, @password = userpass.split(':')
		else
			@username = userpass
			# if darwin
			@password = `security 2>&1 >/dev/null find-internet-password -gs "#{self['.jira.url']}" -a "#{@username}"`
			@password.strip!
			@password.sub!(/^password: "(.*)"$/, '\1')
		end
		return @username
	end
	def password
		return @password unless @username.nil?
		userpass = self['.jira.userpass']
		if userpass.include? ':'
			@username, @password = userpass.split(':')
		else
			@username = userpass
			# if darwin
			@password = `security 2>&1 >/dev/null find-internet-password -gs "#{self['.jira.url']}" -a "#{@username}"`
			@password.strip!
			@password.sub!(/^password: "(.*)"$/, '\1')
		end
		return @password
	end
end

# Load and merge config files.
$cfg = ProjectConfig.new
$cfg.load()

