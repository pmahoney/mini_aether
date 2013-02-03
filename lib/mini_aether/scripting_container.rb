require 'mini_aether/scripting_container_helper'

module MiniAether
  # Not sure why, but using local variables in persistent mode results
  # in odd class loader issues (TypeError: cannot convert instance of
  # class org.jruby.RubyString to class [B) when shuffling data from
  # one container to the other.  That's why the #invoke and #run
  # helpers use global variables, which seems to avoid this issue....
  #
  # TODO: why isn't this using JRuby MVM?  Seems to offer less
  # control, and I've had problems getting it to work as advertised in
  # the past, but possibly worth revisiting.
  # https://github.com/jruby/jruby/blob/master/samples/mvm.rb
  class ScriptingContainer
    include ScriptingContainerHelper

    # Create a new ScriptingContainer (Java object interface to a
    # JRuby runtime) in SINGLETHREAD mode.  #terminate must be called
    # when no longer in use.
    def initialize
      singlethread = Java::OrgJrubyEmbed::LocalContextScope::SINGLETHREAD
      persistent = Java::OrgJrubyEmbed::LocalVariableBehavior::PERSISTENT
      @container = Java::OrgJrubyEmbed::ScriptingContainer.new(singlethread, persistent)
      # short-lived container of mostly java calls may be a bit
      # faster without spending time to JIT
      @container.setCompileMode Java::OrgJruby::RubyInstanceConfig::CompileMode::OFF

      @container.put 'helper', File.expand_path('../scripting_container_helper.rb', __FILE__)
      @container.runScriptlet 'load helper; include MiniAether::ScriptingContainerHelper'
    end

    def terminate
      @container.terminate
    end

    def put(name, object)
      @container.put name.to_s, mini_aether_dump(object)
      @container.runScriptlet("#{name} = mini_aether_load(#{name})")
      nil
    end

    def get(name)
      mini_aether_load(@container.runScriptlet("mini_aether_dump(#{name})"))
    end

    # @param [String] name the name of an object defined in the container
    # @param [String,Symbol] method
    def invoke(name, method, *args)
      put('$method', method.to_s)
      put('$args', args)
      run "#{name}.send($method, *$args)"
    end

    def run(script)
      @container.runScriptlet "$ret = begin \n #{script} \n end"
      get('$ret')
    end
  end
end
