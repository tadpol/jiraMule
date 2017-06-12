require 'mustache'

module JiraMule
  module IRExtend
    # Setup some defaults ones for progress output
    def estimate
      "%.2f"%[(issue[:aggregatetimeoriginalestimate] or 0) / 3600.0]
    end
    def progress
      "%.2f"%[(issue[:aggregatetimespent] or 0) / 3600.0]
    end
    def percent
      percent = issue[:workratio]
      if percent < 0 then
        estimate = (issue[:aggregatetimeoriginalestimate] or 0) / 3600.0
        if estimate > 0 then
          progress = (issue[:aggregatetimespent] or 0) / 3600.0
          percent = (progress / estimate * 100).floor
        else
          percent = 100
        end
      end
      "%.1f"%[percent]
    end
  end

  class IssueRender < Mustache
    def initialize(hsh)
      hsh.each_pair do |k,v|
        self.class.send(:define_method, k.to_sym) {v}
      end
      @issue = hsh
      self.class.send(:define_method, :issue) {@issue}
    end
  end


end
#  vim: set ai et sw=2 ts=2 :
