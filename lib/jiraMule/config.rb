
command :config do |c|
  c.syntax = 'jm confg <key> [<value>]'
  c.summary = 'Modify the config files'
  c.description = 'Easily update bits in the config files.'
  c.example 'Get the jira project name', %{jm config jira.project}
  c.example 'Set the jira project name', %{jm config jira.project jiraMule}
  c.example 'Set a new alias', %{jm config cmd.aliases.p progress}

  # TODO: implement --where.
  c.option '-w', '--where', 'Tell which file this key is found in'

  c.option '-u', '--user', 'Save changes to the file at $HOME'
  c.option '-l', '--local', 'Save changes to the file at $PWD'
  c.option '-p', '--parent', 'Save changes to the file between $PWD and $HOME (if it exists)'

  c.action do |args, options|
      options.default :user => false, :local => false, :parent => false

      if args.count == 1 then
          # This is a read action.
          puts $cfg[args[0]]
          # TODO: pretty the output up

      elsif args.count == 2 then
          # This is a write action.
          level = :local
          level = :parent if options.parent
          level = :user if options.user
          level = :local if options.local
          $cfg.update(args[0], args[1], level)
          #FIXME: handle setting values are an array.
          #  if multiple values, set them as an array.

      end

  end
end

#  vim: set et ai sw=4 ts=4 :
