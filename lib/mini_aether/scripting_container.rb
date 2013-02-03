module MiniAether
  class ScriptingContainer
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
    end

    def terminate
      @container.terminate
    end

    def put(name, object)
      @container.put name.to_s, Marshal.dump(object).to_java
      @container.runScriptlet("#{name} = Marshal.load(#{name})")
      nil
    end

    def get(name)
      Marshal.load(@container.runScriptlet("Marshal.dump(#{name}).to_java"))
    end

    # @param [String] name the name of an object defined in the container
    # @param [String,Symbol] method
    def invoke(name, method, *args)
      @container.put 'method', method.to_s
      @container.put 'args', Marshal.dump(args).to_java
      run <<-EOF
        #{name.to_s}.send(method, *Marshal.load(args))
      EOF
    end

    def run(script)
      @container.runScriptlet <<-EOF
        ret = begin
          #{script}
        end
      EOF
      get('ret')
    end

    def resolve(dependencies, sources)
      with_ruby_container do |c|
        c.put 'path', File.dirname(__FILE__).to_java
        c.put 'deps', Marshal.dump(dependencies).to_java
        c.put 'repos', Marshal.dump(sources).to_java
        files = c.runScriptlet <<-EOF
          $LOAD_PATH.push path
          require 'mini_aether/resolver'
          MiniAether::Resolver.new.resolve_foreign(deps, repos)
        EOF
        files.map { |f| f.to_s }
      end
    end
  end
end
