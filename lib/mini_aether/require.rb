require 'mini_aether/resolver'
require 'mini_aether/spec'

module MiniAether
  module Require
    # Experimental 'require_aether' method for use in irb or just for
    # convenience.  Not threadsafe.
    #
    # @overload require_aether(*coords)
    #   @param [Array<String>] coords one or more colon-separated maven coordinate strings
    #
    # @overload require_aether(*coords, sources)
    #   @param [Array<String>] coords one or more colon-separated maven coordinate strings
    #   @param [Hash] sources a hash with a key +:source+ or +:sources+
    #   and a value of a single string or an array of sources that will be
    #   permanently added to the list of sources
    def require_aether *deps
      @mini_aether_require_spec ||= MiniAether::Spec.new
      @mini_aether_require_resolver ||= MiniAether::Resolver.new

      spec = @mini_aether_require_spec
      resolver = @mini_aether_require_resolver

      if deps.last.kind_of?(Hash)
        hash = deps.pop
        [hash[:source], hash[:sources]].flatten.compact.each do |source|
          spec.source(source)
        end
      end

      deps.each {|coords| spec.jar(coords) }
      resolver.require(spec.dependencies, spec.sources)
      nil
    end

    def require_aether_reset!
      @mini_aether_require_spec = nil
      @mini_aether_require_resolver = nil
    end
  end
end

include MiniAether::Require
