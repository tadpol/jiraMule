require 'pp'
require 'erb'

class CompletionContext < ::Commander::HelpFormatter::Context
end 

class ::Commander::Runner

  # For supporting other shells, this should get replaced with methods that 
  # return parts. Not just a zsh-opt-line.
  def optionLine(option, title=' ')
    if option[:description].lines.count > 1 then
      desc = option[:description].lines[0].chomp.gsub(/'/, '_')
    else
      desc = option[:description].chomp.gsub(/'/, '_')
    end
    values = ''

    # if there is a --[no-]foo format, break that into two switches.
    switches = option[:switches].map{ |s| 
      # TODO: figure out if the switch takes a value, and add the '='
      # Better to figure out what it takes so that can be completed too
      if s =~ /\[no-\]/ then
        [s.sub(/\[no-\]/, ''), s.gsub(/[\[\]]/,'')]
      else
        s
      end
    }.flatten

    if switches.count > 1 then
      return "{#{switches.join(',')}}'[#{desc}]:#{title}:#{values}'"
    else
      return "'#{switches.first}[#{desc}]:#{title}:#{values}'"
    end
  end

  # Not so sure this should go in Runner, but where else?
  def flatswitches(option)
    # if there is a --[no-]foo format, break that into two switches.
    option[:switches].map{ |switch| 
      switch.sub!(/\s.*$/,'') # drop argument spec if exists.
      if switch =~ /\[no-\]/ then
        [switch.sub(/\[no-\]/, ''), switch.gsub(/[\[\]]/,'')]
      else
        switch
      end
    }.flatten
  end
  def takeArg(option)
      # TODO: figure out if the switch takes a value, and add the '='
      # Better to figure out what it takes so that can be completed too

  end

  def optionDesc(option)
    option[:description].sub(/\n.*$/,'')
  end
end

class ::Commander::Command::Options
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

    #pp runner
    if options.gopts then
      opts = runner.instance_variable_get(:@options)
      opts.each do |o|
        puts runner.optionLine o, 'GlobalOption'
      end
      return
    end

    if options.subs then
      runner.instance_variable_get(:@commands).each do |name,cmd|
        #desc = cmd.instance_variable_get(:@summary) #.lines[0]
        #say "#{name}:'#{desc}'"
        say "#{name}"
      end
      return
    end

    if options.opts then
      cmds = runner.instance_variable_get(:@commands)
      pp cmds[options.opts].options
#      cmds[options.opts].options.each do |o|
#        pp o
#        #puts runner.optionLine o
#        puts o.truncDescription
#      end
      return
    end


    tmpl=ERB.new(File.read(File.join(File.dirname(__FILE__), "zshcomplete.erb")), nil, '-<>')

    pc = CompletionContext.new(runner)
    puts tmpl.result(pc.get_binding)


  end
end

#  vim: set ai et sw=2 ts=2 :
