require 'yaml'
require 'pathname'
require 'vine'

class Hash
	def access!(path, value)
		steps = path.to_s.split('.')
		parent = steps[0..-2].join('.')
		child = steps.last

		whom = self.access(parent)
		whom[child] = value
		self
	end
end

class ProjectConfig

	ConfigFile = Struct.new(:kind, :path, :data) do
		def load()
			return if kind == :internal
			self[:path] = Pathname.new(path) unless path.kind_of? Pathname
			self[:data] = Hash.new
			if path.exist? then
				path.open('r') do |fio|
					self[:data] = YAML.load(fio)
				end
			end
		end

		def write()
			return if kind == :internal
			self[:path] = Pathname.new(path) unless path.kind_of? Pathname
			path.open('w') do |fio|
				fio << data.to_yaml
			end
		end
	end

	# Look at parent directories until HOME
	def findProjectFile()
		a = []
		home = Pathname.new(Dir.home)
		pwd = Pathname.new(Dir.pwd)
		return a if home == pwd
		pwd.dirname.ascend{|i| 
			break if i == home
			a << i + '.rpjProject'
		}
		a.select{|i| i.exist? }.map{|i| i.to_s}
	end

	def load()
		@cfg = []
		@cfg << ConfigFile.new(:local, Dir.pwd + '/.rpjProject', {})

		cfgFiles = findProjectFile()
		@cfg += cfgFiles.map do |file|
			ConfigFile.new(:parent, file, {})
		end

		@cfg << ConfigFile.new(:user, ENV['HOME'] + '/.rpjProject', {})

		@cfg << ConfigFile.new(:internal, '', defaultCfgs())

		@cfg.each {|c| c.load}
	end

	def [](key)
		# remove first .
		key = key[1..-1] if key[0] == '.'

		@cfg.each do |acfg|
			v = acfg.data.access(key)
			return v unless v.nil?
		end
		return nil
	end

	def update(key, value, which=:local)
		cfg = @cfg.select{|c| c.kind == which}.first
		return if cfg.nil?
		cfg.data.access!(key, value)
		cfg.write
	end


	# Preloading a bunch of stuff here for the workflows used at my work.
	# XXX Not sure if I should leave these here, or move them to the 'init' subcommand as a set
	# of defaults to be added to a new setup's user config.
	def defaultCfgs()
		return {
			'jira'=>{
				'goto'=>{
					'PSBasic'=>{
						'Open'=>{
							"Dev Ready"=> ["Needs BA"],
							"In Development"=> ["Needs BA", "Dev Ready"],
							"Code Review"=> ["Needs BA", "Dev Ready", "In Development"],
							"QA"=> ["Needs BA", "Dev Ready", "In Development", "Code Review"],
							"QA - Bug Found"=> ["Needs BA", "Dev Ready", "In Development", "Code Review", "QA"],
							"Dev/QA Complete"=> ["Needs BA", "Dev Ready", "In Development", "Code Review", "QA"],
						},
						"Needs BA"=>{
							"In Development"=> ["Dev Ready"],
							"Code Review"=> ["Dev Ready", "In Development"],
							"QA"=> ["Dev Ready", "In Development", "Code Review"],
							"QA - Bug Found"=> ["Dev Ready", "In Development", "Code Review", "QA"],
							"Dev/QA Complete"=> ["Dev Ready", "In Development", "Code Review", "QA"],
						},
						"Dev Ready"=>{
							"Code Review"=> ["In Development"],
							"QA"=> ["In Development", "Code Review"],
							"QA - Bug Found"=> ["In Development", "Code Review", "QA"],
							"Dev/QA Complete"=> ["In Development", "Code Review", "QA"],
						},
						"In Development"=>{
							"Dev Ready"=> ["Code Review"],
							"QA"=> ["Code Review"],
							"QA - Bug Found"=> ["Code Review", "QA"],
							"Dev/QA Complete"=> ["Code Review", "QA"],
						},
						"Code Review"=>{
							"In Development"=> ["Dev Ready"],
							"QA - Bug Found"=> ["QA"],
							"Dev/QA Complete"=> ["QA"],
						}
					},
					"PSStandard"=>{
						# If there is a matching named state, that will always be preferred to the
						# catchall state.
						'Please Estimate' => {
							'Blocked' => ['Open'],
							'In Progress' => ['Open'],
							'Testing' => ['Open', 'In Progress'],
							'Testing - Bug Found' => ['Open', 'In Progress', 'Testing'],
							'Pending Release' => ['Open', 'In Progress'],
							'Released' => ['Open', 'In Progress', 'Pending Release'],
						},
						'Waiting Estimation Approval' => {
							'Blocked' => ['Open'],
							'In Progress' => ['Open'],
							'Testing' => ['Open', 'In Progress'],
							'Testing - Bug Found' => ['Open', 'In Progress', 'Testing'],
							'Pending Release' => ['Open', 'In Progress'],
							'Released' => ['Open', 'In Progress', 'Pending Release'],
						},
						'On Deck' => {
							'Open' => ['Waiting Estimation Approval'],
							'Blocked' => ['Waiting Estimation Approval', 'Open'],
							'In Progress' => ['Waiting Estimation Approval', 'Open'],
							'Testing' => ['Waiting Estimation Approval', 'Open', 'In Progress'],
							'Testing - Bug Found' => ['Waiting Estimation Approval', 'Open', 'In Progress', 'Testing'],
							'Pending Release' => ['Waiting Estimation Approval', 'Open', 'In Progress'],
							'Released' => ['Waiting Estimation Approval', 'Open', 'In Progress', 'Pending Release'],
						},
						'Blocked' => { # Block only goes to Open, In Progress, or Testing
							'Pending Release' => ['In Progress'],
							'Testing - Bug Found' => ['Testing'],
							'Released' => ['Testing', 'Pending Release'],
						},
						'Open' => {
							'Testing' => ['In Progress'],
							'Testing - Bug Found' => ['In Progress', 'Testing'],
							'Pending Release' => ['In Progress'],
							'Released' => ['In Progress', 'Pending Release'],
						},
						'In Progress' => {
							'Open' => ['Blocked'],
							'Released' => ['Pending Release'],
							'Testing - Bug Found' => ['Testing'],
						},
						'Testing' => {
							'Open' => ['Testing - Bug Found'],
							'Released' => ['Pending Release'],
							'In Progress' => ['Testing - Bug Found'],
						},
						'Testing - Bug Found' => {
							'Testing' => ['In Progress'],
							'Pending Release' => ['In Progress'],
							'Released' => ['In Progress', 'Pending Release'],
						},
						'Pending Release' => {
							'In Progress' => ['Reopened'],
							'Testing' => ['Reopened', 'In Progress'],
							'Testing - Bug Found' => ['Reopened', 'In Progress', 'Testing'],
						},
						'Released' => {
							'In Progress' => ['Reopened'],
							'Testing' => ['Reopened', 'In Progress'],
							'Testing - Bug Found' => ['Reopened', 'In Progress', 'Testing'],
							'Pending Release' => ['Reopened', 'In Progress'],
						},
						'*' => {
							'Open' => ['Blocked'], # Anything to Opened via Blocked.
							'Reopened' => ['Closed'] # Anything to Reopened via Closed.
						},
					},
					"PSStaging"=>{
						# '*'=>{'*'=>['Blocked']}
					}
				},
				'next'=>{
					'PSSimple'=>{
						'To do'=>'In Progress',
						'In Progress'=>'Done',
						'Done'=>'To do'
					},
					'PSBasic'=>{
						'Code Review'=>'QA',
						'QA'=>'Dev/QA Complete'
					},
					'PSStandard'=>{
						'Please Estimate'=>'Open',
						'On Deck'=>'Waiting Estimation Approval',
						'Waiting Estimation Approval'=>'Open',
						'Open' => 'In Progress',
						'Blocked'=>'Open',
						'In Progress'=>'Testing',
						'Testing'=>'Pending Release',
						'Pending Release'=>'Released',
						'Released'=>'Closed',
					},
					'PSStaging'=>{
						'Please Estimate'=>'Open',
						'On Deck'=>'Waiting Estimation Approval',
						'Waiting Estimation Approval'=>'Open',
						'Open' => 'In Progress',
						'Blocked'=>'Open',
						'In Progress'=>'Testing',
						'Testing'=>'Pending Staging Release',
						'Pending Staging Release'=>'Released To Staging',
					},
				}
			}
		}
	end
end

# Load and merge config files.
$cfg = ProjectConfig.new
$cfg.load()

#  vim: set sw=2 ts=2 :
