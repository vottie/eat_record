require "test_helper"
require "minitest/mock"

# ステージングの初期データ(#33)。毎回同じ内容になること、他のユーザーに触れないこと、ステージング以外では入らないこと。
class StagingSeedTest < ActiveSupport::TestCase
  EMAIL = "e2e-user@example.com".freeze
  PASSWORD = "seed-test-password".freeze

  setup { StagingSeed.run(email: EMAIL, password: PASSWORD) }

  test "creates the E2E user who can sign in with the given password" do
    user = User.find_by!(email: EMAIL)
    assert user.valid_password?(PASSWORD)
    assert_equal "e2e", user.username
  end

  test "gives the E2E user 27 records, which span two pages of 25" do
    user = User.find_by!(email: EMAIL)
    assert_equal 27, user.eat_records.count
    assert_equal 25, user.eat_records.page(1).count
    assert_equal 2, user.eat_records.page(1).total_pages
  end

  test "records use fixed dates and repeated shops" do
    user = User.find_by!(email: EMAIL)
    dates = user.eat_records.order(:eat_date).pluck(:eat_date)
    assert_equal Date.new(2025, 1, 1), dates.first
    assert_equal 27, dates.uniq.size
    counts = user.eat_records.group(:shop_name).count.values.sort
    assert_equal [ 5, 5, 5, 6, 6 ], counts
  end

  test "records use the values of the new form" do
    user = User.find_by!(email: EMAIL)
    assert_empty user.eat_records.pluck(:usecase).uniq - %w[shop home take_out delivery]
    assert_empty user.eat_records.pluck(:eat_with).uniq - %w[self friends family]
    assert_empty user.eat_records.pluck(:eat_time).uniq - %w[morning lunch dinner]
  end

  test "creates another user with one record, whose password is not the E2E password" do
    other = User.find_by!(email: StagingSeed::OTHER_EMAIL)
    assert_equal 1, other.eat_records.count
    assert_not other.valid_password?(PASSWORD)
  end

  test "running it again gives the same result" do
    before = [ User.count, EatRecord.count ]
    StagingSeed.run(email: EMAIL, password: PASSWORD)
    assert_equal before, [ User.count, EatRecord.count ]
  end

  test "does not touch other users or their records" do
    bystander = users(:alice)
    count = bystander.eat_records.count
    assert_operator count, :>, 0
    StagingSeed.run(email: EMAIL, password: PASSWORD)
    assert User.exists?(bystander.id)
    assert_equal count, bystander.eat_records.reload.count
  end

  test "requires an email and a password" do
    assert_raises(ArgumentError) { StagingSeed.run(email: "", password: PASSWORD) }
    assert_raises(ArgumentError) { StagingSeed.run(email: EMAIL, password: "") }
  end

  # db/seeds.rb
  test "db/seeds.rb adds nothing outside the staging environment" do
    EatRecord.delete_all
    User.delete_all
    load Rails.root.join("db/seeds.rb")
    assert_equal 0, User.count
  end

  test "db/seeds.rb in the staging environment stops on a database that is not for staging" do
    EatRecord.delete_all
    User.delete_all
    ENV["STAGING_E2E_EMAIL"] = EMAIL
    ENV["STAGING_E2E_PASSWORD"] = PASSWORD
    staging = ActiveSupport::EnvironmentInquirer.new("staging")
    Rails.stub :env, staging do
      assert_raises(StagingDatabase::Unsafe) { load Rails.root.join("db/seeds.rb") }
    end
    assert_equal 0, User.count
  ensure
    ENV.delete("STAGING_E2E_EMAIL")
    ENV.delete("STAGING_E2E_PASSWORD")
  end
end
