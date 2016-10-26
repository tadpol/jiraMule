require 'JiraMule/commands/attach.rb'
require 'JiraMule/commands/config.rb'
require 'JiraMule/commands/goto.rb'
require 'JiraMule/commands/init.rb'
require 'JiraMule/commands/kanban.rb'
require 'JiraMule/commands/logWork.rb'
require 'JiraMule/commands/next.rb'
require 'JiraMule/commands/progress.rb'
require 'JiraMule/commands/query.rb'

require 'JiraMule/commands/release.rb'
require 'JiraMule/commands/testReady.rb'
# difference between testReady and release is two things:
# 1. testReady also assigns
# 2. release also transitions
#
# So, merge all that into one command and have the parts be --options; maybe
