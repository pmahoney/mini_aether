require 'mini_aether/scripting_container'

module MiniAether
  # Each MiniAether::Resolver creates a separate ScriptingContainer to
  # hold Aether and various other classes used to resolve and download
  # dependencies.
  class Resolver
    def initialize
      @container = ScriptingContainer.new
      @container.put 'path', File.expand_path('../..', __FILE__)
      @container.put 'level', MiniAether.logger.level
      @container.run <<-EOF
        $LOAD_PATH.push path

        require 'mini_aether/config'
        MiniAether.logger.level = level

        require 'mini_aether/bootstrap'
        MiniAether::Bootstrap.bootstrap!

        require 'mini_aether/resolver_impl'
        resolver = MiniAether::ResolverImpl.new
        nil
      EOF
    end

    # Terminate the underlying ScriptingContainer.  Should be called
    # when this resolver is no longer needed, but is not strictly
    # required.
    def terminate
      @container.terminate
    end

    # Resolve a set of dependencies +dep_hashes+ from repositories
    # +repos+.
    #
    # @param [Array<Hash>] dep_hashes
    #
    # @option dep_hash [String] :group_id the groupId of the artifact
    # @option dep_hash [String] :artifact_id the artifactId of the artifact
    # @option dep_hash [String] :version the version (or range of versions) of the artifact
    # @option dep_hash [String] :extension default to 'jar'
    #
    # @param [Array<String>] repos urls to maven2 repositories
    #
    # @return [Array<String>] list of files
    def resolve(dep_hashes, repos)
      @container.invoke('resolver', 'resolve', dep_hashes, repos)
    end

    # Like #resolve, but requires each resulting jar file.
    def require(deps, repos)
      resolve(deps, repos).each {|jar| Kernel.require jar }
    end
  end
end
