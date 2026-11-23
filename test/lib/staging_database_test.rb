require "test_helper"

# ステージング DB の初期化の守り(#33)。ステージング以外では、何も消さずに中止すること。
class StagingDatabaseTest < ActiveSupport::TestCase
  test "passes for the staging environment with a database name ending in _stg" do
    assert_nil StagingDatabase.ensure_safe!(rails_env: "staging", database: "app_stg")
  end

  test "refuses outside the staging environment even if the name ends in _stg" do
    %w[production development test].each do |env|
      assert_raises(StagingDatabase::Unsafe, env) { StagingDatabase.ensure_safe!(rails_env: env, database: "app_stg") }
    end
  end

  test "refuses a database name that does not end in _stg" do
    [ "app", "app_production", "app_stg_old", "stg", "", nil ].each do |name|
      assert_raises(StagingDatabase::Unsafe, name.inspect) { StagingDatabase.ensure_safe!(rails_env: "staging", database: name) }
    end
  end

  test "the error message does not contain the database name" do
    error = assert_raises(StagingDatabase::Unsafe) { StagingDatabase.ensure_safe!(rails_env: "staging", database: "secret_production") }
    assert_no_match(/secret_production/, error.message)
  end

  test "the test environment's configured database is not accepted as staging" do
    assert_raises(StagingDatabase::Unsafe) { StagingDatabase.ensure_safe! }
  end
end
