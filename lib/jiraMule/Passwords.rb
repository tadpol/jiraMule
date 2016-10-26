require 'uri'
require 'net/http'
require 'json'
require 'date'
require 'pathname'
require 'yaml'
require 'JiraMule/Config'
require 'JiraMule/http'

module JiraMule
  class Passwords
    def initialize(path)
      path = Pathname.new(path) unless path.kind_of? Pathname
      @path = path
      @data = nil
    end
    def load()
      if @path.exist? then
        @path.chmod(0600)
        @path.open('rb') do |io|
          @data = YAML.load(io)
        end
      end
    end
    def save()
      @path.dirname.mkpath unless @path.dirname.exist?
      @path.open('wb') do |io|
        io << @data.to_yaml
      end
      @path.chmod(0600)
    end
    def set(host, user, pass)
      unless @data.kind_of? Hash then
        @data = {host=>{user=>pass}}
        return
      end
      hd = @data[host]
      if hd.nil? or not hd.kind_of?(Hash) then
        @data[host] = {user=>pass}
        return
      end
      @data[host][user] = pass
      return
    end
    def get(host, user)
      return nil unless @data.kind_of? Hash
      return nil unless @data.has_key? host
      return nil unless @data[host].kind_of? Hash
      return nil unless @data[host].has_key? user
      return @data[host][user]
    end
  end

  class Account
    def loginInfo
      host = $cfg['net.host']
      user = $cfg['user.name']
      if user.nil? then
        say_error("No Jira user account found; please login")
        user = ask("User name: ")
        $cfg.set('user.name', user, :user)
      end
      pff = $cfg.file_at('passwords', :user)
      pf = Passwords.new(pff)
      pf.load
      pws = pf.get(host, user)
      if pws.nil? then
        say_error("Couldn't find password for #{user}")
        pws = ask("Password:  ") { |q| q.echo = "*" }
        pf.set(host, user, pws)
        pf.save
      end
      {
        :email => $cfg['user.name'],
        :password => pws
      }
    end
  end
end

#  vim: set ai et sw=2 ts=2 :
