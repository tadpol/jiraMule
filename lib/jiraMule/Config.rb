require 'pathname'
require 'inifile'

module MrMurano
  class Config
    #
    #  internal    transient this-run-only things (also -c options)
    #  specified   from --configfile
    #  env         from ENV['MR_CONFIGFILE']
    #  project     .mrmuranorc at project dir
    #  user        .mrmuranorc at $HOME
    #  system      .mrmuranorc at /etc
    #  defaults    Internal hardcoded defaults
    #
    ConfigFile = Struct.new(:kind, :path, :data) do
      def load()
        return if kind == :internal
        return if kind == :defaults
        self[:path] = Pathname.new(path) unless path.kind_of? Pathname
        self[:data] = IniFile.new(:filename=>path.to_s) if self[:data].nil?
        self[:data].restore
      end

      def write()
        return if kind == :internal
        return if kind == :defaults
        self[:path] = Pathname.new(path) unless path.kind_of? Pathname
        self[:data] = IniFile.new(:filename=>path.to_s) if self[:data].nil?
        self[:data].save
        path.chmod(0600)
      end
    end

    attr :paths
    attr_reader :projectDir

    CFG_SCOPES=%w{internal specified env project private user system defaults}.map{|i| i.to_sym}.freeze
    CFG_FILE_NAME = '.mrmuranorc'.freeze
    CFG_PRVT_NAME = '.mrmuranorc.private'.freeze # Going away.
    CFG_DIR_NAME = '.mrmurano'.freeze
    CFG_ALTRC_NAME = '.mrmurano/config'.freeze
    CFG_SYS_NAME = '/etc/mrmuranorc'.freeze

    def initialize
      @paths = []
      @paths << ConfigFile.new(:internal, nil, IniFile.new())
      # :specified --configfile FILE goes here. (see load_specific)
      unless ENV['MR_CONFIGFILE'].nil? then
        # if it exists, must be a file
        # if it doesn't exist, that's ok
        ep = Pathname.new(ENV['MR_CONFIGFILE'])
        if ep.file? or not ep.exist? then
          @paths << ConfigFile.new(:env, ep)
        end
      end
      @projectDir = findProjectDir()
      unless @projectDir.nil? then
        if (@projectDir + CFG_PRVT_NAME).exist? then
          say_warning "!!! Using .mrmuranorc.private is deprecated"
        end
        @paths << ConfigFile.new(:private, @projectDir + CFG_PRVT_NAME)
        @paths << ConfigFile.new(:project, @projectDir + CFG_FILE_NAME)
        fixModes(@projectDir + CFG_DIR_NAME)
      end
      @paths << ConfigFile.new(:user, Pathname.new(Dir.home) + CFG_FILE_NAME)
      fixModes(Pathname.new(Dir.home) + CFG_DIR_NAME)
      @paths << ConfigFile.new(:system, Pathname.new(CFG_SYS_NAME))
      @paths << ConfigFile.new(:defaults, nil, IniFile.new())


      set('tool.verbose', false, :defaults)
      set('tool.debug', false, :defaults)
      set('tool.dry', false, :defaults)

      set('net.host', 'bizapi.hosted.exosite.io', :defaults)

      set('location.base', @projectDir, :defaults) unless @projectDir.nil?
      set('location.files', 'files', :defaults)
      set('location.endpoints', 'endpoints', :defaults)
      set('location.modules', 'modules', :defaults)
      set('location.eventhandlers', 'eventhandlers', :defaults)
      set('location.roles', 'roles.yaml', :defaults)
      set('location.users', 'users.yaml', :defaults)

      set('files.default_page', 'index.html', :defaults)

      set('eventhandler.skiplist', 'websocket webservice device.service_call', :defaults)

      set('diff.cmd', 'diff -u', :defaults)
    end

    ## Find the root of this project Directory.
    #
    # The Project dir is the directory between PWD and HOME that has one of (in
    # order of preference):
    # - .mrmuranorc
    # - .mrmuranorc.private
    # - .mrmurano/config
    # - .mrmurano/
    # - .git/
    def findProjectDir()
      result=nil
      fileNames=[CFG_FILE_NAME, CFG_PRVT_NAME, CFG_ALTRC_NAME]
      dirNames=[CFG_DIR_NAME]
      home = Pathname.new(Dir.home)
      pwd = Pathname.new(Dir.pwd)
      return nil if home == pwd
      pwd.dirname.ascend do |i|
        break unless result.nil?
        break if i == home
        fileNames.each do |f|
          if (i + f).exist? then
            result = i
          end
        end
        dirNames.each do |f|
          if (i + f).directory? then
            result = i
          end
        end
      end

      # If nothing found, do a last ditch try by looking for .git/
      if result.nil? then
        pwd.dirname.ascend do |i|
          break unless result.nil?
          break if i == home
          if (i + '.git').directory? then
            result = i
          end
        end
      end

      # Now if nothing found, assume it will live in pwd.
      result = Pathname.new(Dir.pwd) if result.nil?
      return result
    end
    private :findProjectDir

    def fixModes(path)
      if path.directory? then
        path.chmod(0700)
      elsif path.file? then
        path.chmod(0600)
      end
    end

    def file_at(name, scope=:project)
      case scope
      when :internal
        root = nil
      when :specified
        root = nil
      when :project
        root = @projectDir + CFG_DIR_NAME
      when :user
        root = Pathname.new(Dir.home) + CFG_DIR_NAME
      when :system
        root = nil
      when :defaults
        root = nil
      end
      return nil if root.nil?
      root.mkpath
      root + name
    end

    ## Load all of the potential config files
    def load()
      # - read/write config file in [Project, User, System] (all are optional)
      @paths.each { |cfg| cfg.load }
    end

    ## Load specified file into the config stack
    # This can be called multiple times and each will get loaded into the config
    def load_specific(file)
      spc = ConfigFile.new(:specified, Pathname.new(file))
      spc.load
      @paths.insert(1, spc)
    end

    ## Get a value for key, looking at the specificed scopes
    # key is <section>.<key>
    def get(key, scope=CFG_SCOPES)
      scope = [scope] unless scope.kind_of? Array
      paths = @paths.select{|p| scope.include? p.kind}

      section, ikey = key.split('.')
      paths.each do |path|
        if path.data.has_section?(section) then
          sec = path.data[section]
          return sec if ikey.nil?
          if sec.has_key?(ikey) then
            return sec[ikey]
          end
        end
      end
      return nil
    end

    ## Dump out a combined config
    def dump()
      # have a fake, merge all into it, then dump it.
      base = IniFile.new()
      @paths.reverse.each do |ini|
        base.merge! ini.data
      end
      base.to_s
    end

    def set(key, value, scope=:project)
      section, ikey = key.split('.', 2)
      raise "Invalid key" if section.nil?
      if not section.nil? and ikey.nil? then
        # If key isn't dotted, then assume the tool section.
        ikey = section
        section = 'tool'
      end

      paths = @paths.select{|p| scope == p.kind}
      raise "Unknown scope" if paths.empty?
      cfg = paths.first
      data = cfg.data
      tomod = data[section]
      tomod[ikey] = value unless value.nil?
      tomod.delete(ikey) if value.nil?
      data[section] = tomod
      cfg.write
    end

    # key is <section>.<key>
    def [](key)
      get(key)
    end

    # For setting internal, this-run-only values
    def []=(key, value)
      set(key, value, :internal)
    end

  end

  ##
  # IF none of -same, then -same; else just the ones listed.
  def self.checkSAME(opt)
    unless opt.files or opt.endpoints or opt.modules or
        opt.eventhandlers or opt.roles or opt.users or opt.spec then
      opt.files = true
      opt.endpoints = true
      opt.modules = true
      opt.eventhandlers = true
    end
    if opt.all then
      opt.files = true
      opt.endpoints = true
      opt.modules = true
      opt.eventhandlers = true
      opt.roles = true
      opt.users = true
    end
  end
end

#  vim: set ai et sw=2 ts=2 :
