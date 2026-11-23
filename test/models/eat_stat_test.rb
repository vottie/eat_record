require "test_helper"

class EatStatTest < ActiveSupport::TestCase
  test "holds a name and a count" do
    stat = EatStat.new
    stat.name = "Ramen Taro"
    stat.count = 2

    assert_equal "Ramen Taro", stat.name
    assert_equal 2, stat.count
  end
end
