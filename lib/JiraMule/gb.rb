require 'pp'

# You don't need this.
# To use this:
# - mkdir -p ~/.jiramule/plugins
# - ln gb.rb ~/.jiramule/plugins

command :_gb do |c|
  c.syntax = %{jm _gb <class> <method> (<args>)}
  c.summary = %{Call internal class methods directly.}
  c.description = %{Call internal class methods directly.}

  c.action do |args, options|
    cls = args[0]
    meth = args[1].to_sym
    args.shift(2)

    begin
      gb = Object::const_get("JiraMule::#{cls}").new
      if gb.respond_to? meth then
        pp gb.__send__(meth, *args)
      else
        say_error "'#{cls}' doesn't '#{meth}'"
      end
    rescue Exception => e
      say_error e.message
      pp e
    end
  end
end


#  vim: set ai et sw=2 ts=2 :
