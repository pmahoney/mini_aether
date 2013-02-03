require 'test_helper'

module MiniAether
  class ResolverTest < MiniTest::Unit::TestCase
    def setup
      @resolver = Resolver.new
    end

    def teardown
      @resolver.terminate
    end

    def test_resolves_artifacts_repeatedly
      deps = [{
                :group_id => 'org.jboss.resteasy',
                :artifact_id => 'resteasy-jaxrs',
                :version => '2.3.4.Final'
              }]
      sources = [MiniAether::MAVEN_CENTRAL_REPO]

      20.times do
        jars = @resolver.resolve(deps, sources).map{|file| File.basename(file, '.jar')}
        assert_equal 12, jars.size
        assert_includes jars, 'resteasy-jaxrs-2.3.4.Final'
        assert_includes jars, 'httpclient-4.1.2'
      end
    end
  end
end
