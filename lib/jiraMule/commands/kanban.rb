require 'terminal-table'
require 'mustache'
require 'yaml'
require 'JiraMule/jiraUtils'

command :kanban do |c|
  extra_columns = []
  c.syntax = 'jm query [options] kanban'
  c.summary = 'Show a kanban table'
  c.description = %{
Display issues grouped by a query.  Each group is a column in a table or a section in a list.

Original intent was to build kanban tables, hence the name.  However, the output is quite
configurable can can be used for many other styles.

Use the --dump option to see how things have been styled.

Formatting is done with Mustash.
  }
  c.example 'Show a kanban table', 'jm kanban'
  c.example 'Show a status list', 'jm status'
  c.example 'Another way to show a status list', 'jm --style status'
  c.example 'Show a list to use with Taskpaper', 'jm --style taskpaper'
  c.example 'Show status list, with differnt styling', %{jm --style status --header '# {{column}}' --item '** {{key}} {{summary}}'}
  c.example 'Showoff', %{jm kanban --style empty --heading '<h1>{{column}}</h1>' \\
  --column 'Working=status="In Progress"' \\
  --column 'Done=status="Pending Release"' \\
  --fields key,summary,assignee \\
  --item '<h2>{{key}}</h2><b>Who:{{assignee.name}}</b><p>{{summary}}</p>'}

  c.option '--[no-]raw', 'Do not prefix queries with project and assignee'
  c.option '-w', '--width WIDTH', Integer, 'Width of the terminal'
  c.option '-s', '--style STYLE', String, 'Which style to use'
  c.option '--heading STYLE', String, 'Format for heading'
  c.option '--item STYLE', String, 'Format for items'
  c.option('-c', '--column NAME=QUERY', '') {|ec| extra_columns << ec}
  c.option '-f', '--fields FIELDS', Array, 'Which fields to return'
  c.option '-d', '--dump', 'Dump the style to STDOUT as yaml'
  c.option '--file FILE', String, %{Style definition file to load}

  c.action do |args, options|
    options.default :width=>HighLine::SystemExtensions.terminal_size[0],
      :style => 'kanban'

    # Table of Styles. Appendable via config file. ??and command line??
    allOfThem = {
      :empty => {
        :fields => [:key, :summary],
        :format => {
          :heading => "{{column}}",
          :item => "{{key}} {{summary}}",
        },
        :columns => {}
      },
      :status => {
        :fields => [:key, :summary],
        :format => {
          :heading => "#### {{column}}",
          :item => "- {{key}} {{summary}}",
          :order => [:Done, :Testing, :InProgress, :Todo],
        },
        :columns => {
          :Done => [%{status = 'Pending Release'}],
          :Testing => [%{status = Testing}],
          :InProgress => [%{status = "In Progress"}],
          :Todo => [%{(status = Open OR},
               %{status = Reopened OR},
               %{status = "On Deck" OR},
               %{status = "Waiting Estimation Approval" OR},
               %{status = "Reopened" OR},
               %{status = "Testing (Signoff)" OR},
               %{status = "Testing (Review)" OR},
               %{status = "Testing - Bug Found")}],
        },

      },
      :kanban => {
        :fields => [:key, :summary],
        :format => {
          :heading => "{{column}}",
          :item => "{{key}}\n {{summary}}",
          :order => [:Todo, :InProgress, :Done],
          :usetable => true
        },
        :columns => {
          :Done => [%{(status = Released OR status = "Not Needed - Closed")}],
          :InProgress => [%{(status = "In Progress" OR},
                          %{status = "In Dev" OR},
                          %{status = "Pending Release" OR},
                          %{status = "In QA" OR},
                          %{status = "Integration QA" OR},
                          %{status = "In Design")},
                  ],
          :Todo => [%{(status = Open OR},
               %{status = Reopened OR},
               %{status = "On Deck" OR},
               %{status = "Waiting Estimation Approval" OR},
               %{status = "Reopened" OR},
               %{status = "Testing (Signoff)" OR},
               %{status = "Testing (Review)" OR},
               %{status = "Testing - Bug Found" OR},
               %{status = "Backlog" OR},
               %{status = "Ready For Dev" OR},
               %{status = "Ready For QA" OR},
               %{status = "To Do" OR},
               %{status = "Release Package")},
            ],
        },
      },
      :taskpaper => {
        :fields => [:key, :summary, :duedate],
        :format => {
          :heading => "{{column}}:",
          :item => "- {{summary}} @jira({{key}}) {{#duedate}}@due({{duedate}}){{/duedate}}",
        },
        :columns => {
          :InProgress => %{status = "In Progress"},
          :Todo => [%{(status = Open OR},
               %{status = "Testing - Bug Found")}],
        }
      },
    }
    # TODO: Load styles from project dir

    if options.file.nil? then
      theStyle = allOfThem[options.style.to_sym]
    else
      theStyle = allOfThem[:empty]
      File.open(options.file) {|io|
        theStyle = YAML.load(io)
        # make sure the required keys are symbols.
        %w{fields format columns}.each do |key|
          if theStyle.has_key? key then
            theStyle[key.to_sym] = theStyle[key]
            theStyle.delete(key)
          end
        end
        %w{heading item}.each do |key|
          if theStyle[:format].has_key? key then
            theStyle[:format][key.to_sym] = theStyle[:format][key]
            theStyle[:format].delete(key)
          end
        end
      }
    end

    #### look for command line overrides
    extra_columns.each do |cm|
      name, query = cm.split(/=/, 2)
      theStyle[:columns][name.to_sym] = [query]
    end

    theStyle[:fields] = options.fields if options.fields
    theStyle[:format][:heading] = options.heading if options.heading
    theStyle[:format][:item] = options.item if options.item


    # All loading and computing of the style is complete, now fetch and print

    if options.dump then
      puts theStyle.to_yaml
    else

      ### Fetch the issues for each column
      columns = theStyle[:columns]

      jira = JiraMule::JiraUtils.new(args, options)

      #### Fetch these fields
      fields = theStyle[:fields]

      #### Now fetch
      qBase = []
      qBase.unshift("assignee = #{jira.username} AND") unless options.raw
      qBase.unshift("project = #{jira.project} AND") unless options.raw
      qBase.unshift('(' + args.join(' ') + ') AND') unless args.empty? 

      results = {}
      columns.each_pair do |name, query|
        query = [query] unless query.is_a? Array
        q = qBase + query + [%{ORDER BY Rank}]
        issues = jira.getIssues(q.join(' '), fields)
        results[name] = issues
      end

      ### Now format the output
      format = theStyle[:format]

      #### Setup ordering
      format[:order] = columns.keys.sort unless format.has_key? :order

      #### setup column widths
      cW = options.width.to_i
      cW = -1 if cW == 0
      cWR = cW
      if format[:usetable] and cW > 0 then
        borders = 4 + (columns.count * 3);   # 2 on left, 2 on right, 3 for each internal
        cW = (cW - borders) / columns.count
        cWR = cW + ((cW - borders) % columns.count)
      end

      #### Format Items
      formatted={}
      results.each_pair do |name, issues|
        formatted[name] = issues.map do |issue|
          line = Mustache.render(format[:item], issue.merge(issue[:fields]))
          #### Trim length?
          if format[:order].last == name
            line[0..cWR]
          else
            line[0..cW]
          end
        end
      end

      #### Print
      if format.has_key?(:usetable) and format[:usetable] then
        # Table type
        #### Pad
        longest = formatted.values.map{|l| l.length}.max
        formatted.each_pair do |name, issues|
          if issues.length <= longest then
            issues.fill(' ', issues.length .. longest)
          end
        end

        #### Transpose
        rows = format[:order].map{|n| formatted[n]}.transpose
        puts Terminal::Table.new :headings => format[:order], :rows=>rows

      else
        # List type
        format[:order].each do |columnName|
          puts Mustache.render(format[:heading], :column => columnName.to_s)
          formatted[columnName].each {|issue| puts issue}
        end
      end
    end
  end
end
alias_command :status, :kanban, '--style', 'status'

#  vim: set sw=2 ts=2 :
