

module JiraMule
  class Style
    def initialize(name, &block)
      @name = name.to_sym
      @fields = [:key, :summary]
      @header = [:key, :summary]
      @footer = nil
      @format_type = :strings
      @format = %{{{key}} {{summary}}}

      @custom_tags = {}

      @prefix_query = nil
      @default_query = nil
      @suffix_query = nil

      @bolden_tag = :bolden

      block.call(self) if block_given?
    end

    ######################################################
    def self.add(style, &block)
      @@styles = {} unless defined?(@@styles)

      if style.kind_of?(String) or style.kind_of?(Symbol) then
        style = Style.new(style, &block)
      end

      @@styles[style.name] = style
    end

    def self.fetch(name)
      @@styles[name.to_sym]
    end

    def self.list
      @@styles.keys
    end

    ######################################################
    # Apply this style to Issues
    # @param issues [Array] Issues from the Jira query to format
    # @return formatted string
    def apply(issues)
      if @format_type == :strings then
        keys = issues.map do |issue|
          fmt = @format
          fmt = fmt.join(' ') if fmt.kind_of? Array
          res = JiraMule::IssueRender.render(fmt, issue.merge(issue[:fields]), @custom_tags)
          bolden(issue, res)
        end
        (@header or '').to_s + keys.join("\n") + (@footer or '').to_s

      elsif [:table, :table_rows, :table_columns].include? @format_type then
        @format = [@format] unless @format.kind_of? Array
        rows = issues.map do |issue|
          issue = issue.merge(issue[:fields])
          @format.map do |col|
            if col.kind_of? Hash then
              col = col.dup
              str = col[:value] or ""
              res = JiraMule::IssueRender.render(str, issue, @custom_tags)
              col[:value] = bolden(issue, res)
              col
            else
              res = JiraMule::IssueRender.render(col, issue, @custom_tags)
              bolden(issue, res)
            end
          end
        end
        if @format_type == :table_columns then
          rows = rows.transpose
        end
        header = (@header or [])
        header = [header] unless header.kind_of? Array
        Terminal::Table.new :headings => header, :rows=>rows
      end
    end

    # If this issue should be bolded or not.
    def bolden(issue, row, color=:bold)
      bld = issue[@bolden_tag]
      bld = @custom_tags[@bolden_tag] if bld.nil?
      bld = bld.call(issue.dup) if bld.kind_of? Proc
      # ? truthy other than Ruby default?
      return row unless bld
      if row.kind_of? Array then
        row.map{|r| HighLine.color(r, color)}
      elsif row.kind_of? Hash then
        hsh={}
        row.each_pair{|k,v| hsh[k] = HighLine.color(v, color)}
      else
        HighLine.color(row.to_s, color)
      end
    end

    # TODO: Dump method that outputs Ruby

    # Build a query based on this Style and other bits from command line
    # @param args [Array<String>] Other bits of JQL to use instead of default_query
    def build_query(*args)
      opts = {}
      opts = args.pop if args.last.kind_of? Hash

      # If nothing from user, and there is a default, start with that.
      if args.empty? and not @default_query.nil? then
        case @default_query
        when Array
          args = @default_query.join(' AND ')
        when Proc
          args = @default_query.call()
        else
          args = @default_query.to_s
        end
        args = [args] unless args.kind_of? Array
      end

      # Get prefix as a String.
      case @prefix_query
      when Array
        prefix = @prefix_query.join(' AND ') + ' AND'
      when Proc
        prefix = @prefix_query.call()
      else
        prefix = @prefix_query.to_s
      end
      args.unshift(prefix) unless opts.has_key? :noprefix

      # Get suffix as a String.
      case @suffix_query
      when Array
        suffix = 'AND ' + @suffix_query.join(' AND ')
      when Proc
        suffix = @suffix_query.call()
      else
        suffix = @suffix_query.to_s
      end
      args.push(suffix) unless opts.has_key? :nosuffix

      args.flatten.compact.join(' ')
    end

    # May need to split this into two classes. One that is the above methods
    # and one that is the below methods.  The below one is used just for the
    # construction of a Style. While the above is the usage of a style.
    #
    # Maybe the above are in a Module, that is included as part of fetch?
    ######################################################

    attr_accessor :prefix_query, :suffix_query, :default_query
    attr_accessor :header

    def name
      @name
    end

    # takes a single flat array of key names.
    def fields(*args)
      return @fields if args.empty?
      @fields = args.flatten.compact.map{|i| i.to_sym}
    end
    alias_method :fields=, :fields

    FORMAT_TYPES = [:strings, :table_rows, :table_columns, :table].freeze
    def format_type(type)
      return @format_type if type.nil?
      raise "Unknown format type: \"#{type}\"" unless FORMAT_TYPES.include? type
      @format_type = type
    end
    alias_method :format_type=, :format_type

    def format(*args)
      return @format if args.empty?
      args.flatten! if args.kind_of? Array
      @format = args
    end
    alias_method :format=, :format

    # Create a custom tag for formatted output
    def add_tag(name, &block)
      @custom_tags[name.to_sym] = block
    end

  end



  Style.add(:basic) do |s|
    s.fields [:key, :summary]
    s.format %{{{key}} {{summary}}}
  end

  Style.add(:info) do |s|
    s.fields [:key, :summary, :description, :assignee, :reporter, :priority,
              :issuetype, :status, :resolution, :votes, :watches]
    s.format %{{{key}}
    Summary: {{summary}}
   Reporter: {{reporter.displayName}}
   Assignee: {{assignee.displayName}}
       Type: {{issuetype.name}} ({{priority.name}})
     Status: {{status.name}} (Resolution: {{resolution.name}})
    Watches: {{watches.watchCount}}  Votes: {{votes.votes}}
Description: {{description}}
    }
  end

  Style.add(:test_table) do |s|
    s.fields [:key, :assignee]
    s.format_type :table_columns
    s.header = nil
    s.format [%{{{key}}}, %{{{assignee.displayName}}}]
  end

  Style.add(:progress) do |s|
    s.fields [:key, :workratio, :aggregatetimespent, :duedate,
              :aggregatetimeoriginalestimate]
    s.format_type :table_rows
    s.header = [:key, :estimated, :progress, :percent, :due]
    s.format [%{{{key}}},
              {:value=>%{{{estimate}}},:alignment=>:right},
              {:value=>%{{{progress}}},:alignment=>:right},
              {:value=>%{{{percent}}%},:alignment=>:right},
              {:value=>%{{{duedate}}},:alignment=>:center},
    ]
    # Use lambda when there is logic that needs to be deferred.
    s.prefix_query = lambda do
      r = []
      r << %{assignee = #{$cfg['user.name']}} unless $cfg['user.name'].nil?
      prjs = $cfg['jira.project']
      unless prjs.nil? then
        r << '(' + prjs.split(' ').map{|prj| %{project = #{prj}}}.join(' OR ') + ')'
      end
      r.join(' AND ') + ' AND'
    end
    s.default_query = %{status = "In Progress"}
    s.suffix_query = %{ORDER BY Rank}

    s.add_tag(:bolden) do |issue|
      estimate = (issue[:aggregatetimeoriginalestimate] or 0)
      progress = (issue[:aggregatetimespent] or 0)
      due = issue[:duedate]
      progress > estimate or (not due.nil? and Date.new >= Date.parse(due))
    end
    s.add_tag(:estimate) do |issue|
      "%.2f"%[(issue[:aggregatetimeoriginalestimate] or 0) / 3600.0]
    end
    s.add_tag(:progress) do |issue|
      "%.2f"%[(issue[:aggregatetimespent] or 0) / 3600.0]
    end
    s.add_tag(:percent) do |issue|
      percent = issue[:workratio]
      if percent < 0 then
        estimate = (issue[:aggregatetimeoriginalestimate] or 0) / 3600.0
        if estimate > 0 then
          progress = (issue[:aggregatetimespent] or 0) / 3600.0
          percent = (progress / estimate * 100).floor
        else
          percent = 100 # XXX ??? what is this line doing? why is it here?
        end
      end
      if percent > 1000 then
        ">1000"
      else
        "%.1f"%[percent]
      end
    end
  end

  Style.add(:todo) do |s|
    s.fields [:key, :summary]
    s.header = "## Todo\n"
    s.format %{- {{key}}\t{{summary}}}

    # Use lambda when there is logic that needs to be deferred.
    s.prefix_query = lambda do
      r = []
      r << %{assignee = #{$cfg['user.name']}} unless $cfg['user.name'].nil?
      prjs = $cfg['jira.project']
      unless prjs.nil? then
        r << '(' + prjs.split(' ').map{|prj| %{project = #{prj}}}.join(' OR ') + ')'
      end
      r.join(' AND ') + ' AND'
    end
    s.default_query = '(' + [%{status = Open},
                       %{status = Reopened},
                       %{status = "On Deck"},
                       %{status = "Waiting Estimation Approval"},
                       %{status = "Reopened"},
                       %{status = "Testing (Signoff)"},
                       %{status = "Testing (Review)"},
                       %{status = "Testing - Bug Found"},
                       %{status = "Backlog"},
                       %{status = "Ready For Dev"},
                       %{status = "Ready For QA"},
                       %{status = "To Do"},
                       %{status = "Release Package"},
    ].join(' OR ') + ')'
    s.suffix_query = %{ORDER BY Rank}
  end

end
#  vim: set ai et sw=2 ts=2 :
