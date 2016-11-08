require 'date'
require 'json'
require 'pp'
require 'JiraMule/Config'
require 'JiraMule/Passwords'
require 'JiraMule/http'
require 'JiraMule/verbosing'

module JiraMule
    class Tempo
        include Verbose
        include Http

        def initialize()
            acc = Account.new
            up = acc.loginInfo
            @username = up[:email]
            @password = up[:password]
        end
        attr_reader :username, :password

        def endPoint(path='')
          URI($cfg['net.url'] + '/rest/tempo-timesheets/3/' + path.to_s)
        end

        # Get worklogs from Tempo plugin
        def workLogs(username, dateFrom=nil, dateTo=nil, project=nil)
            q = {:username => username}
            q[:dateFrom] = DateTime.parse(dateFrom).to_date.iso8601 unless dateFrom.nil?
            q[:dateTo] = DateTime.parse(dateTo).to_date.iso8601 unless dateTo.nil?
            q[:projectKey] = project unless project.nil?
            #q[:accountKey]
            #q[:teamId]

            verbose "Fetching worklogs for #{q}"
            get('worklogs', q)
        end

    end

end

#  vim: set ai et sw=2 ts=2 :
