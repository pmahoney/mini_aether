# This file should typically not be required by user code. Requiring
# this file pulls in many jars onto the classpath (by running
# bootstrap!).  MiniAether.resolve creates a separate ruby runtime in
# a separate classloader which is uses to load this resolver file and
# perform the bootstrapping operation.

require 'mini_aether'
require 'mini_aether/bootstrap'

MiniAether.extend(MiniAether::Bootstrap)
MiniAether.bootstrap!

module MiniAether
  class Resolver
    RepositorySystem =
      Java::OrgSonatypeAether::RepositorySystem

    MavenRepositorySystemSession =
      Java::OrgApacheMavenRepositoryInternal::MavenRepositorySystemSession

    LocalRepository = 
      Java::OrgSonatypeAetherRepository::LocalRepository

    DefaultServiceLocator =
      Java::OrgApacheMavenRepositoryInternal::DefaultServiceLocator

    RepositoryConnectorFactory =
      Java::OrgSonatypeAetherSpiConnector::RepositoryConnectorFactory

    AsyncRepositoryConnectorFactory =
      Java::OrgSonatypeAetherConnectorAsync::AsyncRepositoryConnectorFactory

    FileRepositoryConnectorFactory =
      Java::OrgSonatypeAetherConnectorFile::FileRepositoryConnectorFactory

    Artifact = Java::OrgSonatypeAetherUtilArtifact::DefaultArtifact

    Dependency = Java::OrgSonatypeAetherGraph::Dependency

    RemoteRepository = Java::OrgSonatypeAetherRepository::RemoteRepository

    CollectRequest = Java::OrgSonatypeAetherCollection::CollectRequest

    DependencyRequest = Java::OrgSonatypeAetherResolution::DependencyRequest
    
    PreorderNodeListGenerator = Java::OrgSonatypeAetherUtilGraph::PreorderNodeListGenerator

    # set up connectors for service locator
    LOCATOR = DefaultServiceLocator.new

    MiB_PER_BYTE = 1024.0*1024.0


    services =
      [AsyncRepositoryConnectorFactory,
       FileRepositoryConnectorFactory].map do |klass|
      obj = klass.new
      obj.initService LOCATOR
      obj
    end
    LOCATOR.setServices(RepositoryConnectorFactory.java_class, *services)

    def initialize
      @logger = Java::OrgSlf4j::LoggerFactory.getLogger(self.class.to_s)
      @system = LOCATOR.getService(RepositorySystem.java_class)
      @session = MavenRepositorySystemSession.new
      local_repo = LocalRepository.new(MiniAether.local_repository_path)
      local_manager = @system.newLocalRepositoryManager(local_repo)
      @session.setLocalRepositoryManager(local_manager)
    end

    def new_artifact(hash)
      Artifact.new(hash[:group_id],
                   hash[:artifact_id],
                   hash[:extension] || 'jar',
                   hash[:version])
    end

    # Load dumps of the +dep_hashes+ and +repos+ args using
    # +Marshal.load+ and then call #resolve.  Useful for when the
    # dependencies and repositories are constructed under a different
    # Java classloader.
    def resolve_foreign(deps_data, repos_data)
      resolve(Marshal.load(deps_data), Marshal.load(repos_data))
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
    # @return [Java::JavaUtil::List<Java::JavaIo::File>]
    def resolve(dep_hashes, repos)
      @logger.info 'resolving dependencies ({})', dep_hashes.size
      collect_req = CollectRequest.new

      dep_hashes.each do |hash|
        dep = Dependency.new new_artifact(hash), 'compile'
        collect_req.addDependency dep
        @logger.info 'requested {}', dep
      end

      repos.each do |uri|
        repo = RemoteRepository.new(uri.object_id.to_s, 'default', uri)
        collect_req.addRepository repo
        @logger.info 'added repository {}', repo
      end

      node = @system.collectDependencies(@session, collect_req).getRoot
        
      dependency_req = DependencyRequest.new(node, nil)
      @system.resolveDependencies(@session, dependency_req)
      
      nlg = PreorderNodeListGenerator.new
      node.accept nlg
      files = nlg.getFiles

      @logger.info "resolved with #{files.size} artifacts"

      if @logger.isDebugEnabled
        total_size = 0
        nlg.getArtifacts(false).each do |artifact|
          file = artifact.file
          size = File.stat(artifact.file.absolute_path).size
          total_size += size
          
          @logger.debug("%0.2fMiB %s (%s)" % [size/MiB_PER_BYTE, artifact, file.name])
        end
        @logger.debug("%0.3f MiB total" % [total_size/MiB_PER_BYTE])
      end

      files
    end
  end
end
