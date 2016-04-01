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
		@cfg << defaultCfgs()
	end

	def [](key)
		# remove first .
		key = key[1..-1] if key[0] == '.'

		@cfg.each do |acfg|
			v = acfg.access(key)
			return v unless v.nil?
		end
		return nil
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
						'Waiting Estimation Approval' => {
							'In Progress' => ['Open'],
							'*'=>['Blocked']
						},
						'*'=>{ # TODO: There are a few states that cannot be reached from blocked.
							'*'=>['Blocked']
						}
					},
					"PSStaging"=>{
						'*'=>{'*'=>['Blocked']}
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
