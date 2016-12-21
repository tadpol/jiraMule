require 'date'
require 'json'
require 'pp'
require 'vine'
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
        def workLogs(username=@username, dateFrom=nil, dateTo=nil, project=nil)
            q = {:username => username}
            q[:dateFrom] = DateTime.parse(dateFrom).to_date.iso8601 unless dateFrom.nil?
            q[:dateTo] = DateTime.parse(dateTo).to_date.iso8601 unless dateTo.nil?
            q[:projectKey] = project unless project.nil?
            #q[:accountKey]
            #q[:teamId]

            verbose "Fetching worklogs for #{q}"
            get('worklogs', q)
        end

        ## Submit a timesheet for approval.
        def submitForApproval(period=nil, name=@username, comment='')
          if period.nil? then
            # First day of work week
            cur = currentApprovalStatus(nil, name)
            period = cur.access 'period.dateFrom'
          end
          verbose "Submitting timesheet for #{period}"
          post('timesheet-approval/', {
            :user=>{
              :name=>name,
            },
            :period=>{
              :dateFrom=>period,
            },
            :action=>{
              :name=>:submit,
              :comment=>comment,
            }
          }) unless $cfg['tool.dry']
        end

        def currentApprovalStatus(period=nil, name=@username)
          verbose "Getting current approval status; #{period} #{name}"
          q = {
            :username => name,
          }
          q[:periodStartDate] = period unless period.nil?

          get('timesheet-approval/current/', q)
        end
    end

end

#  vim: set ai et sw=2 ts=2 :
