require 'JiraMule/commands/assign'
require 'JiraMule/commands/attach'
require 'JiraMule/commands/config'
require 'JiraMule/commands/githubImport'
require 'JiraMule/commands/goto'
require 'JiraMule/commands/kanban'
require 'JiraMule/commands/link'
require 'JiraMule/commands/logWork'
require 'JiraMule/commands/next'
require 'JiraMule/commands/progress'
require 'JiraMule/commands/query'
require 'JiraMule/commands/timesheet'

#require 'JiraMule/commands/release'
#require 'JiraMule/commands/testReady'
# difference between testReady and release is two things:
# 1. testReady also assigns
# 2. release also transitions
#
# So, merge all that into one command and have the parts be --options; maybe
