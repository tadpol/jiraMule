require 'pp'

command :completion do |c|
  c.syntax = %{jm completion <> }
  c.summary = %{Tool for getting bits for tab completion.

  For starts, this is zsh only. Because that is what I use.
}
  c.option '--subs', 'List sub commands'
  c.option '--opts', ''

  # - Get sub commands.
  # - get options for a command
  # - dump a completion file that can be loaded into shell

  c.action do |args, options|

    runner = ::Commander::Runner.instance
    if options.subs then
      say runner.instance_variable_get(:@commands).keys.join(' ')
    end

    if options.opts then
      cmds = runner.instance_variable_get(:@commands)
      cmds[args[0]].options.each do |o|
        say "{#{o[:switches].join(',')}}::#{o[:description]}"
      end
    end

  end
end

#  vim: set ai et sw=2 ts=2 :
