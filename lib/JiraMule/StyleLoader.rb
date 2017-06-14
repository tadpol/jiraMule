

module JiraMule
  class Style
    def initialize(name, &block)
      @name = name.to_sym
      @fields = [:key, :summary]
      @headers = [:key, :summary]
      @format_type = :strings
      @format = %{{{key}} {{summary}}}

      loadit(&block) if block_given?
    end

    def loadit(&block)
      block.call(self)
    end

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

    ######################################################
    def name
      @name
    end

    # takes a single flat array of key names.
    def fields(args)
      return @fields if args.nil?
      @fields = args.flatten.map{|i| i.to_sym}
    end
    alias_method :fields=, :fields

    FORMAT_TYPES = [:strings, :table_rows, :table_columns, :table].freeze
    def format_type(type)
      return @format_type if type.nil?
      raise "Unknown format type: \"#{type}\"" unless FORMAT_TYPES.include? type
      @type = type
    end
    alias_method :format_type=, :format_type

    def header(args)
      return @header if args.nil?
      @header = args.flatten.map{|i| i.to_sym}
    end
    alias_method :header=, :header
    alias_method :headers=, :header
    alias_method :headers, :header

    def format(args)
      return @format if args.nil?
      args.flatten! if args.kind_of? Array
      @format = args
    end
    alias_method :format=, :format

    def add_method(name, &block)
    end
  end



#  Style(:basic) do |s|
#    s.fields [:key, :summary]
#    s.format %{{{key}} {{summary}}}
#  end
#
#  Style(:info) do |s|
#    s.fields [:key, :summary, :description, :assignee, :reporter, :priority,
#              :issuetype, :status, :resolution, :votes, :watches]
#    s.format %{{{key}}
#    Summary: {{summary}}
#   Reporter: {{reporter.displayName}}
#   Assignee: {{assignee.displayName}}
#       Type: {{issuetype.name}} ({{priority.name}})
#     Status: {{status.name}} (Resolution: {{resolution.name}})
#    Watches: {{watches.watchCount}}  Votes: {{votes.votes}}
#Description: {{description}}
#    }
#  end
#
#  Style(:progress) do |s|
#    s.fields [:key, :workratio, :aggregatetimespent, :duedate,
#              :aggregatetimeoriginalestimate]
#    s.format_type :table_rows
#    s.header [:key, :estimated, :progress, :percent, :due]
#    s.format [%{{{key}}},
#              {:value=>%{{{estimate}}},:alignment=>:right},
#              {:value=>%{{{progress}}},:alignment=>:right},
#              {:value=>%{{{percent}}},:alignment=>:right},
#              {:value=>%{{{duedate}}},:alignment=>:center},
#    ]
#
#    s.add_method(:estimate) do
#    end
#  end

end
#  vim: set ai et sw=2 ts=2 :
