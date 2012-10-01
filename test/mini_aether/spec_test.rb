require 'test_helper'

module MiniAether
  class SpecTest < MiniTest::Unit::TestCase
    def test_hash_arg
      spec = Spec.new do
        dep(:group_id => 'group',
            :artifact_id => 'artifact',
            :version => '1')
      end

      hash = {
        :group_id => 'group',
        :artifact_id => 'artifact',
        :version => '1'
      }
      assert_equal hash, spec.dependencies.first
    end

    def assert_deps(spec)
      hash = {
        :group_id => 'group',
        :artifact_id => 'artifact',
        :version => '1'
      }

      spec.dependencies.each do |dep|
        assert_equal hash, dep
      end
    end

    def test_full_coords
      assert_deps(Spec.new do
                    jar 'group:artifact:1'
                  end)
    end

    def test_default_group
      assert_deps(Spec.new do
                    group 'group' do
                      jar 'artifact:1'
                    end
                  end)
    end

    def test_default_group_and_version
      assert_deps(Spec.new do
                    group 'group' do
                      version '1' do
                        jar 'artifact'
                      end
                    end
                  end)
    end

    def test_default_version
      assert_deps(Spec.new do
                    version '1' do
                      jar 'group:artifact'
                    end
                  end)
    end

    def test_default_version2
      assert_deps(Spec.new do
                    group 'bad' do
                      version '1' do
                        jar 'group:artifact'
                      end
                    end
                  end)
    end
  end
end
