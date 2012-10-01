require 'test_helper'

class InterpolateTest < MiniTest::Unit::TestCase
  def test_passes_through_plain_string
    strs = [
            'hello',
            '$ { nope } ',
            'text${text',
            'a a a a'
           ]
    strs.each do |str|
      assert_equal str, Aether.interpolate(str)
    end
  end

  def test_interpolates_env_vars
    key = '__AETHER_INTERPOLATE_TEST__'
    ENV[key] = 'value'
    assert_equal 'value', Aether.interpolate("${env.#{key}}")
    assert_equal 'aaa value', Aether.interpolate("aaa ${env.#{key}}")
    assert_equal 'value aaa', Aether.interpolate("${env.#{key}} aaa")
    assert_equal 'value}', Aether.interpolate("${env.#{key}}}")
    assert_equal 'avaluea', Aether.interpolate("a${env.#{key}}a")

    assert_equal 'a value a value a', Aether.interpolate("a ${env.#{key}} a ${env.#{key}} a")
  ensure
    ENV[key] = nil
  end

  def test_empty_string_when_no_env_var
    assert_nil ENV['NO_SUCH_ENV_VAR']
    assert_equal '', Aether.interpolate("${env.NO_SUCH_ENV_VAR}")
  end

  def test_interpolates_system_props
    key = '__AETHER_INTERPOLATE_TEST__'
    sys = Java::JavaLang::System
    sys.setProperty(key, 'value')

    assert_equal 'value', Aether.interpolate("${#{key}}")
    assert_equal 'aaa value', Aether.interpolate("aaa ${#{key}}")
    assert_equal 'value aaa', Aether.interpolate("${#{key}} aaa")
    assert_equal 'value}', Aether.interpolate("${#{key}}}")
    assert_equal 'avaluea', Aether.interpolate("a${#{key}}a")

    assert_equal 'a value a value a', Aether.interpolate("a ${#{key}} a ${#{key}} a")
  ensure
    sys.clearProperty(key)
  end

  def test_empty_string_when_no_sys_prop
    sys = Java::JavaLang::System
    assert_nil sys.getProperty 'NO_SUCH_ENV_VAR'
    assert_equal '', Aether.interpolate("${NO_SUCH_ENV_VAR}")
  end
end

