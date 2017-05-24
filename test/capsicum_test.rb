require 'test_helper'

class CapsicumTest < Minitest::Test
  # This is going to get awkward...
  i_suck_and_my_tests_are_order_dependent!

  def test_that_it_has_a_version_number
    refute_nil ::Capsicum::VERSION
  end

  def test_1_within_sandbox
    refute Capsicum.sandboxed?

    result = Capsicum.within_sandbox do
      begin
        Capsicum.sandboxed? == true || Process.exit!(1)
        File.new("/dev/null")
      rescue Errno::ECAPMODE
        Process.exit!(0)
      else
        Process.exit!(2)
      end
    end

    assert result.exitstatus.zero?
    refute Capsicum.sandboxed?
  end

  # After this test we're in capability mode and cannot escape.
  def test_2_capsicum
    refute Capsicum.sandboxed?
    assert Capsicum.enter!
    assert Capsicum.sandboxed?

    assert_raises(Errno::ECAPMODE) do
      File.new("/dev/null")
    end

    assert_raises(Errno::ECAPMODE) do
      puts `ls`
    end
  end
end
