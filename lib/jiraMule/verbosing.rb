require 'pp'

module JiraMule
  module Verbose

    def verbose(msg)
      if $cfg['tool.verbose'] then
        say "\033[1m=#\033[0m #{msg}"
      end
    end

    def debug(msg)
      if $cfg['tool.debug'] then
        say "\033[1m=#\033[0m #{msg}"
      end
    end

    def printVars(map)
      $stdout.print("\033[1m=:\033[0m ")
      map.each {|k,v|
        $stdout.print("\033[1m#{k}:\033[0m #{v}  ")
      }
      $stdout.print("\n")
    end

  end
end
#  vim: set ai et sw=2 ts=2 :
