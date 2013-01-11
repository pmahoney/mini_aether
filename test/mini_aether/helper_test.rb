require 'test_helper'
require 'mini_aether/helper'

module MiniAether
  class HelperTest < MiniTest::Unit::TestCase
    class InterpolateTest < MiniTest::Unit::TestCase
      include Helper

      def test_passes_through_plain_string
        strs = [
                'hello',
                '$ { nope } ',
                'text${text',
                'a a a a'
               ]
        strs.each do |str|
          assert_equal str, interpolate(str)
        end
      end

      def test_interpolates_env_vars
        key = '__AETHER_INTERPOLATE_TEST__'
        ENV[key] = 'value'
        assert_equal 'value', interpolate("${env.#{key}}")
        assert_equal 'aaa value', interpolate("aaa ${env.#{key}}")
        assert_equal 'value aaa', interpolate("${env.#{key}} aaa")
        assert_equal 'value}', interpolate("${env.#{key}}}")
        assert_equal 'avaluea', interpolate("a${env.#{key}}a")

        assert_equal 'a value a value a', interpolate("a ${env.#{key}} a ${env.#{key}} a")
      ensure
        ENV[key] = nil
      end

      def test_empty_string_when_no_env_var
        assert_nil ENV['NO_SUCH_ENV_VAR']
        assert_equal '', interpolate("${env.NO_SUCH_ENV_VAR}")
      end

      def test_interpolates_system_props
        key = '__AETHER_INTERPOLATE_TEST__'
        sys = Java::JavaLang::System
        sys.setProperty(key, 'value')

        assert_equal 'value', interpolate("${#{key}}")
        assert_equal 'aaa value', interpolate("aaa ${#{key}}")
        assert_equal 'value aaa', interpolate("${#{key}} aaa")
        assert_equal 'value}', interpolate("${#{key}}}")
        assert_equal 'avaluea', interpolate("a${#{key}}a")

        assert_equal 'a value a value a', interpolate("a ${#{key}} a ${#{key}} a")
      ensure
        sys.clearProperty(key)
      end

      def test_empty_string_when_no_sys_prop
        sys = Java::JavaLang::System
        assert_nil sys.getProperty 'NO_SUCH_ENV_VAR'
        assert_equal '', interpolate("${NO_SUCH_ENV_VAR}")
      end
    end
  end
end
