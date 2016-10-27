require 'JiraMule/Config'

command :config do |c|
  c.syntax = %{jm config [options] <key> [<new value>]}
  c.summary = %{Get and set options}
  c.description = %{
  You can get, set, or query config options with this command.  All config
  options are in a 'section.key' format.  There is also a layer of scopes
  that the keys can be saved in.
  }

  c.example %{See what the current combined config is}, 'jm config --dump'
  c.example %{Query a value}, 'jm config jira.project'
  c.example %{Set a new value; writing to the project config file}, 'jm config jira.project XXXXXXXX'
  c.example %{Set a new value; writing to the user config file}, 'jm config --user user.name my@email.address'
  c.example %{Unset a value in a configfile. (lower scopes will become visible if set)},
    'jm config diff.cmd --unset'


  c.option '--system', 'Use only the system config file. (/etc/jiramulerc)'
  c.option '--user', 'Use only the config file in $HOME (.jiramulerc)'
  c.option '--project', 'Use only the config file in the project (.jiramulerc)'
  c.option '--env', 'Use only the config file from $JM_CONFIGFILE'
  c.option '--specified', 'Use only the config file from the --config option.'

  c.option '--unset', 'Remove key from config file.'
  c.option '--dump', 'Dump the current combined view of the config'

  c.action do |args, options|

    if options.dump then
      puts $cfg.dump()
    elsif args.count == 0 then
      say_error "Need a config key"
    elsif args.count == 1 and not options.unset then
      options.defaults :system=>false, :user=>false, :project=>false,
        :specified=>false, :env=>false

      # For read, if no scopes, than all. Otherwise just those specified
      scopes = []
      scopes << :system if options.system
      scopes << :user if options.user
      scopes << :project if options.project
      scopes << :env if options.env
      scopes << :specified if options.specified
      scopes = JiraMule::Config::CFG_SCOPES if scopes.empty?

      say $cfg.get(args[0], scopes)
    else

      options.defaults :system=>false, :user=>false, :project=>true,
        :specified=>false, :env=>false
      # For write, if scope is specified, only write to that scope.
      scope = :project
      scope = :system if options.system
      scope = :user if options.user
      scope = :project if options.project
      scope = :env if options.env
      scope = :specified if options.specified

      args[1] = nil if options.unset
      $cfg.set(args[0], args[1], scope)
    end
  end

end

#  vim: set ai et sw=2 ts=2 :
