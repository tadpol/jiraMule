require 'pp'
require 'erb'

class CompletionContext < ::Commander::HelpFormatter::Context
end 

class ::Commander::Runner

  # Not so sure this should go in Runner, but where else?

  ##
  # Change the '--[no-]foo' switch into '--no-foo' and '--foo'
  def flatswitches(option)
    # if there is a --[no-]foo format, break that into two switches.
    option[:switches].map{ |switch| 
      switch = switch.sub(/\s.*$/,'') # drop argument spec if exists.
      if switch =~ /\[no-\]/ then
        [switch.sub(/\[no-\]/, ''), switch.gsub(/[\[\]]/,'')]
      else
        switch
      end
    }.flatten
  end

  ##
  # If the switches take an argument, retun =
  def takesArg(option, yes='=', no='')
    if option[:switches].select { |switch| switch =~ /\s\S+$/ }.empty? then
      no
    else
      yes
    end
  end

  ##
  # truncate the description of an option
  def optionDesc(option)
    option[:description].sub(/\n.*$/,'')
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

    #pp runner
    if options.gopts then
      opts = runner.instance_variable_get(:@options)
      pp opts.first
      pp runner.takesArg(opts.first)
#      opts.each do |o|
#        puts runner.optionLine o, 'GlobalOption'
#      end
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
      cmd = cmds[options.opts]
      pp cmd.syntax
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
