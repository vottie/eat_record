require "test_helper"
require "rake"

# bin/rails staging:reset(#33)。ステージング以外では、データを消さずに中止すること。
class StagingResetTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("staging:reset")
    Rake::Task["staging:reset"].reenable
  end

  test "aborts and keeps the data when run outside staging" do
    users = User.count
    records = EatRecord.count
    assert_operator users, :>, 0

    assert_raises(StagingDatabase::Unsafe) { Rake::Task["staging:reset"].invoke }

    assert_equal users, User.count
    assert_equal records, EatRecord.count
  end
end
