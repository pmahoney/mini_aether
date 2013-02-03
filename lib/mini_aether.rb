require 'java'
require 'logger'

require 'mini_aether/config'
require 'mini_aether/resolver'
require 'mini_aether/spec'

module MiniAether
  class << self
    # Resolve +dependencies+, downloading from +sources+.
    #
    # Uses a separate classloader to avoid polluting the classpath
    # with Aether and SLF4J classes.
    #
    # @param [Array<Hash>] dependencies
    #
    # @option dependency [String] :group_id the groupId of the artifact
    # @option dependency [String] :artifact_id the artifactId of the artifact
    # @option dependency [String] :version the version (or range of versions) of the artifact
    # @option dependency [String] :extension default to 'jar'
    #
    # @param [Array<String>] repos urls to maven2 repositories
    #
    # @return [Array<String>] an array of paths to artifact files
    # (likely jar files) satisfying the dependencies
    def resolve(dependencies, sources)
      resolver = Resolver.new
      begin
        resolver.resolve(dependencies, sources)
      ensure
        resolver.terminate
      end
    end

    # Meant to be called once to resolve, possibly download, and
    # require a set of jar dependencies.
    def setup(&block)
      resolver = Resolver.new
      begin
        spec = Spec.new(&block)
        resolver.resolve(spec.dependencies, spec.sources).each do |jar|
          require jar
        end
      ensure
        resolver.terminate
      end
    end
  end
end
