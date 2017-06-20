

module JiraMule
  class Style
    def initialize(name, &block)
      @name = name.to_sym
      @fields = [:key, :summary]
      @headers = [:key, :summary]
      @format_type = :strings
      @format = %{{{key}} {{summary}}}

      @custom_tags = {}

      @prefix_query = nil
      @default_query = nil
      @suffix_query = nil
      # TODO: Add default query (This should replace the --raw thing.)

      # TODO: Add bolding rule for rows and/or cells.

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
          JiraMule::IssueRender.render(fmt, issue.merge(issue[:fields]), @custom_tags)
        end
        keys.join("\n")

      elsif [:table, :table_rows, :table_columns].include? @format_type then
        @format = [@format] unless @format.kind_of? Array
        rows = issues.map do |issue|
          issue = issue.merge(issue[:fields])
          @format.map do |col|
            if col.kind_of? Hash then
              col = col.dup
              str = col[:value] or ""
              col[:value] = JiraMule::IssueRender.render(str, issue, @custom_tags)
              col
            else
              JiraMule::IssueRender.render(col, issue, @custom_tags)
            end
          end
        end
        if @format_type == :table_columns then
          rows = rows.transpose
        end
        Terminal::Table.new :headings => (@headers or []), :rows=>rows
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
      args.unshift(prefix)

      # Get suffix as a String.
      case @suffix_query
      when Array
        suffix = 'AND ' + @suffix_query.join(' AND ')
      when Proc
        suffix = @suffix_query.call()
      else
        suffix = @suffix_query.to_s
      end
      args.push(suffix)

      args.flatten.compact.join(' ')
    end

    # May need to split this into two classes. One that is the above methods
    # and one that is the below methods.  The below one is used just for the
    # construction of a Style. While the above is the usage of a style.
    #
    # Maybe the above are in a Module, that is included as part of fetch?
    ######################################################

    attr_accessor :prefix_query, :suffix_query, :default_query

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

    def header(*args)
      return @headers if args.empty?
      @headers = args.flatten.compact.map{|i| i.to_sym}
    end
    alias_method :header=, :header
    alias_method :headers=, :header
    alias_method :headers, :header

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
    s.header nil
    s.format [%{{{key}}}, %{{{assignee.displayName}}}]
  end

  Style.add(:progress) do |s|
    s.fields [:key, :workratio, :aggregatetimespent, :duedate,
              :aggregatetimeoriginalestimate]
    s.format_type :table_rows
    s.header [:key, :estimated, :progress, :percent, :due]
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
      r << %{project = #{$cfg['jira.project']}} unless $cfg['jira.project'].nil?
      r.join(' AND ') + ' AND'
    end
    s.default_query = %{status = "In Progress"}
    s.suffix_query = %{ORDER BY Rank}

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

end
#  vim: set ai et sw=2 ts=2 :
