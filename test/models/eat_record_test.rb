require "test_helper"

class EatRecordTest < ActiveSupport::TestCase
  test "fixtures belong to their users" do
    assert_equal 3, EatRecord.where(user_id: users(:alice).id).count
    assert_equal 1, EatRecord.where(user_id: users(:bob).id).count
  end

  test "can be saved with attributes" do
    record = EatRecord.create!(shop_name: "New Shop", eat_date: Date.new(2025, 4, 1), user_id: users(:alice).id)

    assert record.persisted?
    assert_equal "New Shop", EatRecord.find(record.id).shop_name
  end
end
