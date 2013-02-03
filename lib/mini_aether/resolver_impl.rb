# This file should not be required by normal code.  It can only be
# loaded into a bootstrapped environment. MiniAether::Resolver
# prepares such an environment.

require 'set'

require 'mini_aether/helper'

module MiniAether
  class ResolverImpl
    MiB_PER_BYTE = 1024.0*1024.0

    java_import java.lang.System

    java_import org.apache.maven.repository.internal.DefaultServiceLocator
    java_import org.apache.maven.repository.internal.MavenRepositorySystemSession
    java_import org.slf4j.LoggerFactory
    java_import org.sonatype.aether.RepositorySystem
    java_import org.sonatype.aether.collection.CollectRequest
    java_import org.sonatype.aether.connector.async.AsyncRepositoryConnectorFactory
    java_import org.sonatype.aether.connector.file.FileRepositoryConnectorFactory
    java_import org.sonatype.aether.graph.Dependency
    java_import org.sonatype.aether.repository.LocalRepository
    java_import org.sonatype.aether.repository.RemoteRepository
    java_import org.sonatype.aether.resolution.DependencyRequest
    java_import org.sonatype.aether.spi.connector.RepositoryConnectorFactory
    java_import org.sonatype.aether.util.artifact.DefaultArtifact
    java_import org.sonatype.aether.util.graph.PreorderNodeListGenerator

    # for loading ~/.m2/settings.xml
    java_import org.apache.maven.settings.building.DefaultSettingsBuilderFactory
    java_import org.apache.maven.settings.building.DefaultSettingsBuildingRequest
    java_import org.apache.maven.settings.building.SettingsBuildingException

    DEFAULT_LOCAL_REPOSITORY =
      File.join(System.getProperty('user.home'), '.m2', 'repository').freeze
    DEFAULT_USER_SETTINGS =
      File.join(System.getProperty('user.home'), '.m2', 'settings.xml').freeze

    # slf4j logger
    attr_reader :logger

    # maven settings from settings.xml
    attr_reader :settings

    # For now, array of string repository urls.  In the future, likely
    # Repository objects for applying additional details.
    attr_reader :repositories

    # path to local repository
    attr_reader :local_repository

    def initialize
      @logger = LoggerFactory.getLogger(self.class.to_s)

      # set up connectors for service locator
      locator = DefaultServiceLocator.new
      services = [AsyncRepositoryConnectorFactory,
                  FileRepositoryConnectorFactory].map do |klass|
        obj = klass.new
        obj.initService locator
        obj
      end
      locator.setServices(RepositoryConnectorFactory.java_class, *services)

      @system = locator.getService(RepositorySystem.java_class)

      load_maven_settings!
    end

    def load_maven_settings!
      settings_builder = DefaultSettingsBuilderFactory.new.newInstance

      request = DefaultSettingsBuildingRequest.new
      if System.getProperty('maven.home')
        global_settings = File.join(System.getProperty('maven.home'), 'conf', 'settings.xml')
        request.setGlobalSettingsFile(Java::JavaIo::File.new(global_settings))
        logger.debug('set global settings file to {}', global_settings)
      end
      request.setUserSettingsFile(Java::JavaIo::File.new(DEFAULT_USER_SETTINGS))
      logger.debug('set user settings file to {}', DEFAULT_USER_SETTINGS)
      request.setSystemProperties(System.getProperties)

      begin
        result = settings_builder.build(request)
        result.getProblems.each do |prob|
          logger.warn 'problem reading settings: {}', prob
        end
        @settings = result.getEffectiveSettings
      rescue SettingsBuildingException => e
        raise e.message
      end

      @local_repository = settings.localRepository || DEFAULT_LOCAL_REPOSITORY
      logger.debug('using local repository {}', local_repository)

      active = Set.new
      settings.activeProfiles.each { |id| active << id }

      @repositories = []
      settings.getProfilesAsMap.each do |id, profile|
        if active.include?(id)
          logger.debug 'processing profile {}', id
          profile.repositories.each do |repo|
            # TODO: release/snapshot, various other details
            @repositories << repo.url
          end
        else
          logger.debug 'skipping inactive profile {}', id
        end
      end
    end
    private :load_maven_settings!

    def new_artifact(hash)
      DefaultArtifact.new(hash[:group_id],
                          hash[:artifact_id],
                          hash[:extension] || 'jar',
                          hash[:version])
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
      logger.info 'resolving dependencies'
      
      session = MavenRepositorySystemSession.new
      local_repo = LocalRepository.new(local_repository)
      local_manager = @system.newLocalRepositoryManager(local_repo)
      session.setLocalRepositoryManager(local_manager)

      collect_req = CollectRequest.new

      dep_hashes.each do |hash|
        dep = Dependency.new new_artifact(hash), 'compile'
        collect_req.addDependency dep
        logger.debug 'requested {}', dep
      end

      (self.repositories + repos).each do |uri|
        repo = RemoteRepository.new(uri.object_id.to_s, 'default', uri)
        collect_req.addRepository repo
        logger.info 'added repository {}', repo.getUrl

        begin
          enabled = []
          enabled << 'releases' if repo.getPolicy(false).isEnabled
          enabled << 'snapshots' if repo.getPolicy(true).isEnabled
          logger.debug '{}', enabled.join('+')
        end
      end

      node = @system.collectDependencies(session, collect_req).getRoot
        
      dependency_req = DependencyRequest.new(node, nil)
      @system.resolveDependencies(session, dependency_req)
      
      nlg = PreorderNodeListGenerator.new
      node.accept nlg

      if logger.isDebugEnabled
        total_size = 0
        nlg.getArtifacts(false).each do |artifact|
          file = artifact.file
          size = File.stat(artifact.file.absolute_path).size
          total_size += size
          
          logger.debug("Using %0.2f %s" % [size/MiB_PER_BYTE, artifact])
        end
        logger.debug('      -----')
        logger.debug("      %0.2f MiB total" % [total_size/MiB_PER_BYTE])
      else
        nlg.getArtifacts(false).each do |artifact|
          logger.info 'Using {}', artifact
        end
      end

      nlg.getFiles.map{|e| e.to_s }
    end
  end
end
