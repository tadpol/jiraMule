require 'pp'

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
  # script format.

  c.action do |args, options|

    runner = ::Commander::Runner.instance
    #pp runner
    if options.gopts then
      opts = runner.instance_variable_get(:@options)
      opts.each do |o|
        say "{#{o[:switches].join(',')}}::#{o[:description]}"
      end
    end

    if options.subs then
      say runner.instance_variable_get(:@commands).keys.join(' ')
    end

    if options.opts then
      cmds = runner.instance_variable_get(:@commands)
      cmds[options.opts].options.each do |o|
        say "{#{o[:switches].join(',')}}::#{o[:description]}"
      end
    end

  end
end

#  vim: set ai et sw=2 ts=2 :
