require 'mustache'

module JiraMule
  class IssueRender < Mustache
    def initialize(hsh)
      hsh.each_pair do |k,v|
        self.class.send(:define_method, k.to_sym) {v}
      end
      @issue = hsh
      self.class.send(:define_method, :issue) {@issue}
    end

    # We're not doing HTML, so never escape.
    def escapeHTML(str)
      str
    end

    def self.render(tmpl, issue, custom_tags={})
      r = self.new(issue.dup)
      custom_tags.each_pair do |name, blk|
        r[name.to_sym] = lambda do
          blk.call(issue.dup)
        end
      end
      r.render(tmpl)
    end
  end

#  # something simpler than Mustache?
#  class IssueRender2
#    def initialize(hsh)
#      @issue = hsh
#    end
#    def [](key)
#      @issue[key]
#    end
#    def []=(key,value)
#      @issue[key] = value
#    end
#    def render(tmpl)
#      tmpl.to_s.gsub(/%(.*)%/) do
#        if $& == '%%' then
#          '%'
#        elsif @issue.has_key?($1.to_sym) then
#          v = @issue[$1.to_sym]
#          pp v
#          if v.kind_of?(Proc) then
#            #v.call(@issue.dup)
#            v[@issue.dup]
#          else
#            v.to_s
#          end
#        else
#          # No replacements, just return what we found.
#          $&
#        end
#      end
#    end
#
#    def self.render(tmpl, issue, custom_tags={})
#      r = self.new(issue)
#      custom_tags.each_pair do |name, blk|
#        r[name.to_sym] = blk
#      end
#      r.render(tmpl)
#    end
#
#  end
end

#  vim: set ai et sw=2 ts=2 :
