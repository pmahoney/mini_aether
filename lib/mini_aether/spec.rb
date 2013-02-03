require 'mini_aether/config'

module MiniAether
  # A DSL to define and resolve dependencies.  The Maven central
  # repository is included by default.
  #
  # Example:
  #
  #
  class Spec
    class << self
      def attr(*syms)
        syms.each do |sym|
          _attr(sym)
        end
      end

      def _attr(sym)
        define_method(sym) do |*args, &block|
          value = if args && args.size > 0
                    args[0]
                  else
                    nil
                  end

          iv = "@#{sym}".to_sym
          if value
            raise ArgumentError 'no effect without block' unless block
            orig = instance_variable_get iv
            instance_variable_set iv, value
            begin
              block.call
            ensure
              instance_variable_set iv, orig
            end
          else
            instance_variable_get iv
          end
        end
      end
    end

    attr_reader :dependencies, :sources

    attr :group, :version

    def initialize(&block)
      @sources = [MAVEN_CENTRAL_REPO]
      @dependencies = []

      if block_given?
        instance_eval(&block)
      end
    end

    # Add a maven repository URL to the list of sources.
    def source(uri)
      sources << uri
    end

    # Declare a dependency using an explicit hash of parameters.
    #
    # @param [Hash] dependency
    # @option dependency [String] :group_id the groupId of the artifact
    # @option dependency [String] :artifact_id the artifactId of the artifact
    # @option dependency [String] :version the version (or range of versions) of the artifact
    # @option dependency [String] :extension defaults to 'jar'
    def dep(dep_hash)
      dependencies << dep_hash
    end

    def jar(coords)
      dependencies << to_hash(coords)
    end

    def to_hash(coords)
      components = coords.split(':')
      case components.size
      when 1
        {
          :group_id => group,
          :artifact_id => components[0],
          :version => version
        }
      when 2
        if components[1] =~ /^\d/
          {
            :group_id => group,
            :artifact_id => components[0],
            :version => components[1]
          }
        else
          {
            :group_id => components[0],
            :artifact_id => components[1],
            :version => version
          }
        end
      when 3
        {
          :group_id => components[0],
          :artifact_id => components[1],
          :version => components[2]
        }
      else
        raise ArgumentError, "don't understand '#{coords}'"
      end
    end
  end
end
