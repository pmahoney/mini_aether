require 'test_helper'

module MiniAether
  class ScriptingContainerTest < MiniTest::Unit::TestCase
    def setup
      @container = ScriptingContainer.new
    end

    def teardown
      @container.terminate
    end

    def test_puts_and_gets_objects
      hash = {:a => 1, :b => 2}
      @container.put('obj', hash)
      assert_equal hash, @container.get('obj')
    end

    def test_manipulates_object
      @container.put('myobj', {:a => 1, :b => 2})
      @container.invoke('myobj', '[]=', :c, 3)
      assert_equal({:a => 1, :b => 2, :c => 3}, @container.get('myobj'))
    end

    def test_runs_script
      ret = @container.run <<-EOF
        hash = {:a => 1, :b => 2}
        hash[:c] = 3
        hash
      EOF
      assert_equal({:a => 1, :b => 2, :c => 3}, ret)
    end

    def test_repeats_roundtrips
      obj = [1,2,3]
      20.times do
        @container.put('obj', obj)
        assert @container.invoke('obj', :include?, 2)
        assert_equal obj, @container.get('obj')
      end
    end

    def test_repeats_roundtrips_global
      obj = [1,2,3]
      name = '$obj'
      20.times do
        @container.put(name, obj)
        assert @container.invoke(name, :include?, 2)
        assert_equal obj, @container.get(name)
      end
    end
  end
end
