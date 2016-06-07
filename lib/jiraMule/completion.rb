require 'pp'
require 'erb'

class CompletionContext < ::Commander::HelpFormatter::Context
end 

class ::Commander::Runner
  def optionLine(option, title=' ')
    if option[:description].lines.count > 1 then
      desc = option[:description].lines[0].chomp.gsub(/'/, '_')
    else
      desc = option[:description].chomp.gsub(/'/, '_')
    end
    values = ''
    switch = option[:switches].join(',')

    if option[:switches].count > 1 then
      return "{#{switch}}'[#{desc}]:#{title}:#{values}'"
    else
      return "'#{switch}[#{desc}]:#{title}:#{values}'"
    end
  end
end

command :completion do |c|
  c.syntax = %{jm completion [options] }
  c.summary = %{Tool for getting bits for tab completion.}
  c.description = %{
  For starts, this is zsh only. Because that is what I use.
}
  c.option '--subs', 'List sub commands'
  c.option '--opts CMD', 'List options for subcommand'
  c.option '--gopts', 'List global options'

  # - dump a completion file that can be loaded into shell

  # it feels like I could make a HelpFormatter that actually dumps in a completion
  # script format. Yes, but it doesn't save any work to do it that way.
  # well it might.
  #
  # Changing direction.
  # Will poop out the file to be included as the completion script.

  c.action do |args, options|

    runner = ::Commander::Runner.instance

    tmpl=ERB.new(File.read(File.join(File.dirname(__FILE__), "zshcomplete.erb")), nil, '-')

    pc = CompletionContext.new(runner)
    say tmpl.result(pc.get_binding)



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
