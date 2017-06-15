

module JiraMule
  class Style
    def initialize(name, &block)
      @name = name.to_sym
      @fields = [:key, :summary]
      @headers = [:key, :summary]
      @format_type = :strings
      @format = %{{{key}} {{summary}}}

      @prefix_query = nil
      @default_query = nil
      @suffix_query = nil
        # TODO: Add default query (This should replace the --raw thing.)

        # TODO: Add bolding rule for rows and/or cells.
      loadit(&block) if block_given?
    end

    def loadit(&block)
      block.call(self)
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
          JiraMule::IssueRender.render(@format, issue.merge(issue[:fields]))
        end
        keys.join("\n")

      elsif [:table, :table_rows, :table_columns].include? @format_type then
        @format = [@format] unless @format.kind_of? Array
        rows = issues.map do |issue|
          @format.map do |col|
            if col.kind_of? Hash then
              str = col[:value] or ""
              col[:value] = JiraMule::IssueRender.render(str, issue.merge(issue[:fields]))
              col
            else
              JiraMule::IssueRender.render(col, issue.merge(issue[:fields]))
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
      args.flatten!
      args = @default_query if args.empty? and not @default_query.nil?
      args.unshift(@prefix_query) unless @prefix_query.nil?
      args.push(@suffix_query) unless @suffix_query.nil?
      args.join(' ')
    end

    # May need to split this into two classes. One that is the above methods
    # and one that is the below methods.  The below one is used just for the
    # construction of a Style. While the above is the usage of a style.
    #
    # Maybe the above are in a Module, that is included as part of fetch?
    ######################################################
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
      @type = type
    end
    alias_method :format_type=, :format_type

    def header(*args)
      return @header if args.empty?
      @header = args.flatten.compact.map{|i| i.to_sym}
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

    # This will be for adding computed fields for the output formatter.
    def add_method(name, &block)
      # TODO figure this out
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
              {:value=>%{{{percent}}},:alignment=>:right},
              {:value=>%{{{duedate}}},:alignment=>:center},
    ]
#    s.prefix_query = %{assignee = #{} AND }
#    s.default_query = %{status = "In Progress"}
#    s.suffix_query = %{ ORDER BY Rank}

    s.add_method(:estimate) do
    end
  end

end
#  vim: set ai et sw=2 ts=2 :
