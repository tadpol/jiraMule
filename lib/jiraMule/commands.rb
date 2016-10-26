require 'jiraMule/commands/attach.rb'
require 'jiraMule/commands/config.rb'
require 'jiraMule/commands/goto.rb'
require 'jiraMule/commands/init.rb'
require 'jiraMule/commands/kanban.rb'
require 'jiraMule/commands/logWork.rb'
require 'jiraMule/commands/next.rb'
require 'jiraMule/commands/progress.rb'
require 'jiraMule/commands/query.rb'

require 'jiraMule/commands/release.rb'
require 'jiraMule/commands/testReady.rb'
# difference between testReady and release is two things:
# 1. testReady also assigns
# 2. release also transitions
#
# So, merge all that into one command and have the parts be --options; maybe
