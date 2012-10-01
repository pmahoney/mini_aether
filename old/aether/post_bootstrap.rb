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

  class << self
    def new_system
      LOCATOR.getService RepositorySystem.java_class
    end

    def new_session
      MavenRepositorySystemSession.new
    end

    def new_local_repository(path = local_repository_path)
      LocalRepository.new path
    end

    def new_artifact(hash)
      Artifact.new(hash[:group_id],
                   hash[:artifact_id],
                   hash[:extension] || 'jar',
                   hash[:version])
    end

    def resolve(dep_hashes, repos)
      system = new_system
      session = new_session
      local_manager = system.newLocalRepositoryManager new_local_repository
      session.setLocalRepositoryManager local_manager

      collect_req = CollectRequest.new

      dep_hashes.each do |hash|
        dep = Dependency.new new_artifact(hash), 'compile'
        collect_req.addDependency dep
      end

      repos.each do |uri|
        repo = RemoteRepository.new(uri.object_id.to_s, 'default', uri)
        collect_req.addRepository repo
      end
      
      node = system.collectDependencies(session, collect_req).getRoot
      
      dependency_req = DependencyRequest.new(node, nil)
      system.resolveDependencies(session, dependency_req)
      
      nlg = PreorderNodeListGenerator.new
      node.accept nlg
      puts nlg.getFiles.map{|f| f.to_s}.join("\n")
    end
  end
end
