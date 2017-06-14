

module JiraMule
  class Style
    def initialize(name, &block)
    end
  end



  Style(:basic) do |s|
    fields [:key, :summary]
    s.format %{{{key}} {{summary}}}
  end

  Style(:info) do
    fields [:key, :summary, :description, :assignee, :reporter, :priority,
            :issuetype, :status, :resolution, :votes, :watches]
    format %{{{key}}
    Summary: {{summary}}
   Reporter: {{reporter.displayName}}
   Assignee: {{assignee.displayName}}
       Type: {{issuetype.name}} ({{priority.name}})
     Status: {{status.name}} (Resolution: {{resolution.name}})
    Watches: {{watches.watchCount}}  Votes: {{votes.votes}}
Description: {{description}}
        }
  end

  Style(:progress) do
    fields [:key, :workratio, :aggregatetimespent, :duedate,
            :aggregatetimeoriginalestimate]
    format_type :table_rows
    header [:key, :estimated, :progress, :percent, :due]
    format [%{{{key}}},
            {:value=>%{{{estimate}}},:alignment=>:right},
            {:value=>%{{{progress}}},:alignment=>:right},
            {:value=>%{{{percent}}},:alignment=>:right},
            {:value=>%{{{duedate}}},:alignment=>:center},
    ]

    add_method(:estimate) do
    end
  end

end
#  vim: set ai et sw=2 ts=2 :
