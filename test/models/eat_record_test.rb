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

  test "every attribute is stored and read back" do
    record = EatRecord.create!(
      shop_name: "Shop", place_name: "Place", usecase: "店", eat_with: "友達",
      eat_date: Date.new(2025, 4, 1), eat_time: "夜", eat_menu: "Menu", article: "Memo", user_id: users(:alice).id
    )
    loaded = EatRecord.find(record.id)

    assert_equal %w[Shop Place 店 友達 夜 Menu Memo], [ :shop_name, :place_name, :usecase, :eat_with, :eat_time, :eat_menu, :article ].map { |attribute| loaded.public_send(attribute) }
    assert_equal Date.new(2025, 4, 1), loaded.eat_date
    assert_equal users(:alice).id, loaded.user_id
  end

  test "a date that does not exist is stored as nil, not as another date" do
    record = EatRecord.create!(shop_name: "Shop", eat_date: "2025-02-30", user_id: users(:alice).id)

    assert_nil record.reload.eat_date
  end

  test "a record whose user does not exist is rejected by the database" do
    assert_raises(ActiveRecord::InvalidForeignKey) do
      EatRecord.create!(shop_name: "Orphan", user_id: 0)
    end
  end

  test "long text in the memo is stored in full" do
    record = EatRecord.create!(shop_name: "Shop", article: "あ" * 200, user_id: users(:alice).id)

    assert_equal 200, record.reload.article.length
  end
end
