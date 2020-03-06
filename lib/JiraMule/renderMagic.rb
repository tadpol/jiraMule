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
end

#  vim: set ai et sw=2 ts=2 :
