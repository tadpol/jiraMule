require 'yaml'
require 'pathname'
require 'vine'

class ProjectConfig

	def findProjectFile()
		a = []
		home = Pathname.new(Dir.home)
		Pathname.new(Dir.pwd).ascend{|i| 
			break if i == home
			a << i + '.rpjProject'
		}
		a.select{|i| i.exist? }.map{|i| i.to_s}
	end

	def load()
		cfgFiles = findProjectFile() + [ ENV['HOME'] + '/.rpjProject']
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

