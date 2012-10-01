require 'aether/dsl'

module Aether
  System = Java::JavaLang::System

  MAVEN_CENTRAL_REPO = 'http://repo1.maven.org/maven2'.freeze

  M2_SETTINGS = File.join(ENV['HOME'], '.m2', 'settings.xml').freeze

  class << self
    def with_ruby_container
      scope = Java::OrgJrubyEmbed::LocalContextScope::THREADSAFE
      c = Java::OrgJrubyEmbed::ScriptingContainer.new(scope)
      begin
        yield c
      ensure
        c.terminate
      end
    end

    def resolve(dependencies, sources)
      with_ruby_container do |c|
        c.put 'path', File.dirname(__FILE__)
        c.put 'deps', Marshal.dump(dependencies).to_java
        c.put 'repos', Marshal.dump(sources).to_java
        files = c.runScriptlet <<-EOF
          $LOAD_PATH.push path
          require 'aether'
          require 'aether/resolver'
          Aether::Resolver.new.resolve_foreign(deps, repos)
        EOF
        files.map{|f| f.to_s}
      end
    end

    def setup(&block)
      Aether::Dsl.new(&block).require
    end
  end
end
