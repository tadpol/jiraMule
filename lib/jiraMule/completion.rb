require 'pp'
require 'erb'

command :completion do |c|
  c.syntax = %{jm completion [options] }
  c.summary = %{Tool for getting bits for tab completion.

  For starts, this is zsh only. Because that is what I use.
}
  c.option '--subs', 'List sub commands'
  c.option '--opts CMD', 'List options for subcommand'
  c.option '--gopts', 'List global options'

  # - dump a completion file that can be loaded into shell

  # it feels like I could make a HelpFormatter that actually dumps in a completion
  # script format. Yes, but it doesn't save any work to do it that way.

  c.action do |args, options|

    runner = ::Commander::Runner.instance

    #pp runner
    if options.gopts then
      opts = runner.instance_variable_get(:@options)
      opts.each do |o|

        desc = o[:description].lines[0].chomp.gsub(/'/, '_')
        values = ''
        switch = o[:switches].join(',')

        #say "#{switch}[#{desc}]:Global Option:#{values}"
        if o[:switches].count > 1 then
          say "{#{switch}}[#{desc}]:GlobalOption:#{values}"
        else
          say "#{switch}[#{desc}]:GlobalOption:#{values}"
        end
      end
    end

    if options.subs then
      runner.instance_variable_get(:@commands).each do |name,cmd|
        #desc = cmd.instance_variable_get(:@summary) #.lines[0]
        #say "#{name}:'#{desc}'"
        say "#{name}"
      end
    end

    if options.opts then
      cmds = runner.instance_variable_get(:@commands)
      cmds[options.opts].options.each do |o|
        #say "{#{o[:switches].join(',')}}: :'#{o[:description]}'"
        desc = o[:description] #
        desc = desc.lines[0].chomp.gsub(/'/, '_') if desc.lines.count > 1
        values = ''
        switch = o[:switches].join(',')

        #say "#{switch}[#{desc}]:Global Option:#{values}"
        if o[:switches].count > 1 then
          say "{#{switch}}'[#{desc}]: :#{values}'"
        else
          say "'#{switch}[#{desc}]: :#{values}'"
        end
      end
    end

  end
end

#  vim: set ai et sw=2 ts=2 :