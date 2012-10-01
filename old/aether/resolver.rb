require 'aether/bootstrap'

module Aether
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

  services =
    [AsyncRepositoryConnectorFactory,
     FileRepositoryConnectorFactory].map do |klass|
    obj = klass.new
    obj.initService LOCATOR
    obj
  end
  LOCATOR.setServices(RepositoryConnectorFactory.java_class, *services)

  class Resolver
    def initialize
      @logger = Java::OrgSlf4j::LoggerFactory.getLogger(self.class.to_s)
      @system = LOCATOR.getService RepositorySystem.java_class
      @session = MavenRepositorySystemSession.new
      local_repo = LocalRepository.new(Aether.local_repository_path)
      local_manager = @system.newLocalRepositoryManager(local_repo)
      @session.setLocalRepositoryManager local_manager
    end

    def new_artifact(hash)
      Artifact.new(hash[:group_id],
                   hash[:artifact_id],
                   hash[:extension] || 'jar',
                   hash[:version])
    end

    def resolve_foreign(deps_data, repos_data)
      resolve(Marshal.load(deps_data), Marshal.load(repos_data))
    end

    def resolve(dep_hashes, repos)
      @logger.info "resolving dependencies (#{dep_hashes.size})"
      collect_req = CollectRequest.new

      dep_hashes.each do |hash|
        dep = Dependency.new new_artifact(hash), 'compile'
        collect_req.addDependency dep
      end

      repos.each do |uri|
        repo = RemoteRepository.new(uri.object_id.to_s, 'default', uri)
        collect_req.addRepository repo
      end

      node = @system.collectDependencies(@session, collect_req).getRoot
        
      dependency_req = DependencyRequest.new(node, nil)
      @system.resolveDependencies(@session, dependency_req)
      
      nlg = PreorderNodeListGenerator.new
      node.accept nlg
      files = nlg.getFiles
      @logger.info "resolved with #{files.size} files"
      files
    end
  end
end
