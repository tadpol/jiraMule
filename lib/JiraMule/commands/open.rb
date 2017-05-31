require 'shellwords'

command :open do |c|
  c.syntax = 'jm open [options] <keys...> '
  c.summary = 'Open issues in web browser'

  c.action do |args, options|
    jira = JiraMule::JiraUtils.new(args, options)
    keys = jira.expandKeys(args)
    jira.printVars(:key=>keys)
    urls = keys.map{|key| "#{$cfg['net.url']}/browse/#{key}"}

    ocmd = $cfg['open-url.cmd']
    if ocmd.nil? then
      say_error "No open command!"
      exit 2
    end
    ocmd = ocmd.shellsplit
    urls.each do |url|
      dcmd = ocmd + [url]
      say "R: #{dcmd.join(' ')}" if $cfg['tool.verbose']
      system(*dcmd) unless $cfg['tool.dry']
    end
  end
end

#  vim: set ai et sw=2 ts=2 :
