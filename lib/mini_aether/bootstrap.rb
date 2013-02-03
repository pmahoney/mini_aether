require 'fileutils'
require 'net/http'
require 'tmpdir'
require 'uri'

require 'mini_aether/config'
require 'mini_aether/helper'
require 'mini_aether/spec'
require 'mini_aether/xml_parser'

module MiniAether
  module Bootstrap
    class << self
      include Helper

      def bootstrap!
        logback = false
        root = local_repository_path
        dependencies.each do |dep|
          # means slf4j backend was not found, and we should initialize logback
          if dep[:artifact_id] == 'logback-classic'
            logback = true
          end
          jar = ensure_dependency(dep, root)
          require jar
        end

        initialize_logback if logback
      end

      def initialize_logback
        file = File.expand_path('../logback.xml', __FILE__)
        context = Java::OrgSlf4j::LoggerFactory.getILoggerFactory
        begin
          configurator = Java::ChQosLogbackClassicJoran::JoranConfigurator.new
          configurator.setContext context
          context.reset
          context.putProperty("level", MiniAether.logger.level)
          configurator.doConfigure(file)
        rescue Java::ChQosJoranException.java_class
          # StatusPrinter will handle this
        end
        Java::ChQosLogbackCoreUtil::StatusPrinter.printInCaseOfErrorsOrWarnings context
      end

      # Pre-resolved dependencies of mini_aether.  This list includes a
      # set of dependencies and all transient dependencies.
      def dependencies
        mini_aether_spec.dependencies
      end

      # Pre-resolved (dependencies including all transients) spec of
      # the (bootsrap) dependencies of mini_aether itself.
      #
      # @return [MiniAether::Spec] the dependencies of mini_aether itself
      def mini_aether_spec
        Spec.new do
          group 'org.sonatype.aether' do
            version '1.13.1' do
              jar 'aether-api'
              jar 'aether-connector-asynchttpclient'
              jar 'aether-connector-file'
              jar 'aether-impl'
              jar 'aether-spi'
              jar 'aether-util'
            end
          end

          jar 'com.ning:async-http-client:1.6.5'
          jar 'org.jboss.netty:netty:3.2.5.Final'
          jar 'org.slf4j:slf4j-api:1.6.2'

          begin
            Java::OrgSlf4jImpl::StaticLoggerBinder
          rescue NameError
            # use logback when no slf4j backend exists
            jar 'ch.qos.logback:logback-core:1.0.6'
            jar 'ch.qos.logback:logback-classic:1.0.6'
          end

          group 'org.apache.maven' do
            version '3.0.4' do
              jar 'maven-aether-provider'
              jar 'maven-model'
              jar 'maven-model-builder'
              jar 'maven-repository-metadata'
            end
          end

          group 'org.codehaus.plexus' do
            jar 'plexus-interpolation:1.14'
            jar 'plexus-component-annotations:1.5.5'
            jar 'plexus-utils:2.0.6'
          end
        end
      end

      # Build a m2 repository path fragment for +dep+.  For example,
      # coordinates of +com.example:project:1.0.1+ would result in
      # +com/example/project/1.0.1/project-1.0.1.jar+.
      #
      # @param [Hash] dep a hash with keys +:group_id+, +:artifact_id+, and +:version+
      # @return [String] a path fragment to this artifact in m2 repository format
      def jar_path(dep)
        group_id = dep[:group_id]
        group_path = group_id.gsub('.', '/')
        artifact_id = dep[:artifact_id]
        version = dep[:version]

        file_name = "#{artifact_id}-#{version}.jar"
        "#{group_path}/#{artifact_id}/#{version}/#{file_name}"
      end

      def ensure_dependency(dep, root)
        path = jar_path(dep)
        local_file = File.join(root, path)
        install(path, local_file) unless File.exists?(local_file)
        local_file
      end

      def install(path, file, repo = MAVEN_CENTRAL_REPO)
        if MiniAether.logger.info?
          puts "[mini_aether] INFO  bootstrap installing #{File.basename(path)}"
        end

        remote_base = File.dirname(path) + '/' + File.basename(path, File.extname(path))
        local_dir = File.dirname(file)
        local_base = File.join(local_dir, File.basename(file, File.extname(file)))

        exts = [File.extname(path), '.pom', '.pom.sha1']
        exts.each do |ext|
          uri = URI("#{repo}/#{remote_base}#{ext}")
          local_file = local_base + ext

          Net::HTTP.start(uri.host, uri.port) do |http|
            request = Net::HTTP::Get.new uri.request_uri
            
            http.request request do |response|
              unless response.code == '200'
                raise "#{response.code} #{response.message}: #{uri}"
              end

              FileUtils.mkdir_p local_dir
              open local_file, 'w' do |io|
                response.read_body do |chunk|
                  io.write chunk
                end
              end
            end
          end
        end
      end
    end
  end
end
