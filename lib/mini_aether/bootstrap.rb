require 'mini_aether/spec'
require 'mini_aether/xml_parser'
require 'fileutils'
require 'net/http'
require 'strscan'
require 'tmpdir'
require 'uri'

module MiniAether
  module Bootstrap
    System = Java::JavaLang::System

    # Pre-resolved dependencies of mini_aether.
    def dependencies
      spec = Spec.new do
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
          # add dir to classpath since it contains logback.xml
          $CLASSPATH << File.expand_path(File.dirname(__FILE__))
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

      spec.dependencies
    end

    # Interpolate variables like +${user.home}+ and +${env.HOME}+ from
    # system properties and environment variables respectively.
    def interpolate(str)
      ret = ''

      s = StringScanner.new(str)
      pos = s.pos

      while s.scan_until(/\$\{[^\s}]+\}/) # match ${stuff}
        # add the pre_match, but only starting from previous position
        ret << str.slice(pos, (s.pos - pos - s.matched.size))

        # interpolate
        var = s.matched.slice(2..-2)
        ret << case var
               when /^env\.(.*)/
                 ENV[$1] || ''
               else
                 System.getProperty(var) || ''
               end

        pos = s.pos
      end
      ret << s.rest
      
      ret
    end

    def local_repository_path
      default_local_repo_path =
        File.join(System.getProperty('user.home'), '.m2', 'repository')

      if File.exists? M2_SETTINGS
        xml = File.read M2_SETTINGS
        begin
          parser = XmlParser.new(xml)
          parser.pull_to_path(:settings, :localRepository)
          interpolate(parser.pull_text_until_end.strip)
        rescue XmlParser::NotFoundError
          default_local_repo_path
        end
      else
        default_local_repo_path
      end
    end

    def ensure_dependency(dep)
      path = jar_path(dep)
      local_file = File.join(local_repository_path, path)
      install(path, local_file) unless File.exists?(local_file)
      local_file
    end

    # Load the required jar files, downloading them if necessary.
    #
    # Ignores any maven config regarding repositories and attempts a
    # direct download from repo1.maven.org using Net::HTTP.
    def bootstrap!
      dependencies.each do |dep|
        require ensure_dependency(dep)
      end
    end

    def install(path, file, repo = MAVEN_CENTRAL_REPO)
      print "installing #{File.basename(path)}... "
      $stdout.flush

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

        print "#{ext} "
        $stdout.flush
      end
      puts
    end

    def jar_path(dep)
      group_id = dep[:group_id]
      group_path = group_id.gsub('.', '/')
      artifact_id = dep[:artifact_id]
      version = dep[:version]

      file_name = "#{artifact_id}-#{version}.jar"
      "#{group_path}/#{artifact_id}/#{version}/#{file_name}"
    end
  end
end
