require 'test_helper'

require 'tmpdir'

class MiniAetherTest < MiniTest::Unit::TestCase
  System = Java::JavaLang::System

  def test_bootstrap
    orig_home = System.getProperty('user.home')
    begin
      Dir.mktmpdir do |dir|
        System.setProperty('user.home', dir)

        deps = [{
                  :group_id => 'net.jcip',
                  :artifact_id => 'jcip-annotations',
                  :version => '1.0'
                }]
        sources = [MiniAether::MAVEN_CENTRAL_REPO]
        MiniAether.resolve(deps, sources)

        files = Dir["#{dir}/.m2/**/*.jar"].map{|file| File.basename(file, '.jar')}
        assert_includes files, 'aether-api-1.13.1'
      end
    ensure
      System.setProperty('user.home', orig_home)
    end
  end

  def test_resolves_dependencies
    deps = [{
              :group_id => 'org.jboss.resteasy',
              :artifact_id => 'resteasy-jaxrs',
              :version => '2.3.4.Final'
            }]
    sources = [MiniAether::MAVEN_CENTRAL_REPO]
    jars = MiniAether.resolve(deps, sources).map{|file| File.basename(file, '.jar')}

    assert_equal 12, jars.size
    assert_includes jars, 'resteasy-jaxrs-2.3.4.Final'
    assert_includes jars, 'httpclient-4.1.2'
  end
end
