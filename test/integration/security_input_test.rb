require "test_helper"

# 入力の扱い(#69)。許可していないパラメータの無視、出力のエスケープ、不正な値の扱い、リダイレクト先の制限。
class SecurityInputTest < ActionDispatch::IntegrationTest
  SCRIPT = "<script>alert('x')</script>".freeze
  ESCAPED = "&lt;script&gt;alert(&#39;x&#39;)&lt;/script&gt;".freeze

  setup do
    @alice = users(:alice)
  end

  def all_fields(value)
    { shop_name: value, place_name: value, usecase: value, eat_with: value, eat_menu: value, article: value }
  end

  test "values are escaped on every page that shows a record" do
    sign_in @alice
    post new_eat_record_path, params: { eat_record: all_fields(SCRIPT).merge(eat_date: "2025-05-01") }
    record = EatRecord.find_by!(user_id: @alice.id, eat_date: "2025-05-01")

    [ eat_record_path(record), edit_eat_record_path(record), eat_records_path, stat_eat_records_path ].each do |path|
      sign_in @alice
      get path
      assert_response :success, "GET #{path}"
      assert_not_includes response.body, SCRIPT, "#{path} に、エスケープされていない値がある"
      assert_includes response.body, ESCAPED, "#{path}"
    end
  end

  test "a username is escaped" do
    @alice.update!(username: SCRIPT)
    sign_in @alice
    get eat_records_path

    assert_not_includes response.body, SCRIPT
    assert_includes response.body, ESCAPED
  end

  test "unpermitted record attributes are ignored" do
    sign_in @alice
    post new_eat_record_path, params: { eat_record: { shop_name: "Strict", id: 999_999, created_at: "2000-01-01", updated_at: "2000-01-01" } }
    record = EatRecord.find_by!(shop_name: "Strict")

    assert_not_equal 999_999, record.id
    assert_operator record.created_at.year, :>, 2000
  end

  test "sign up accepts only the username in addition to the credentials" do
    signup_open!
    post user_registration_path, params: { user: { username: "newbie", email: "newbie@example.com",
                                                   password: "password123", password_confirmation: "password123",
                                                   provider: "google_oauth2", uid: "forged-uid" } }

    user = User.find_by!(email: "newbie@example.com")
    assert_nil user.provider
    assert_nil user.uid
  end

  test "SQL-like text is stored as text and does not widen the query" do
    sign_in users(:bob)
    post new_eat_record_path, params: { eat_record: { shop_name: "x' OR '1'='1", eat_date: "2025-06-01" } }
    assert_equal "x' OR '1'='1", EatRecord.find_by!(eat_date: "2025-06-01").shop_name

    sign_in @alice
    get eat_records_path
    assert_select "span.eatrec-row1 a", text: "x' OR '1'='1", count: 0
    assert_select "span.eatrec-row1", count: 3
  end

  test "unusual page parameters do not break the index" do
    sign_in @alice
    [ "0", "-1", "abc", "1' OR '1'='1", "999999", "1.5", "" ].each do |page|
      sign_in @alice
      get eat_records_path, params: { page: page }
      assert_response :success, "page=#{page.inspect}"
    end
  end

  # ログイン後の移動先は、常にアプリ内の固定の画面。パラメータや保存された URL で、外部へ移動させない
  test "sign in always goes to the index, whatever the redirect parameters say" do
    post user_session_path, params: { user: { email: @alice.email, password: "password123" },
                                      redirect_to: "https://evil.example/", return_to: "https://evil.example/",
                                      user_return_to: "https://evil.example/" }

    assert_redirected_to eat_records_path
  end

  test "sign in after visiting a protected page does not return to an external address" do
    get "/eat_records?redirect_to=https://evil.example/"
    assert_redirected_to new_user_session_path

    post user_session_path, params: { user: { email: @alice.email, password: "password123" } }
    assert_redirected_to eat_records_path
  end

  test "sign out goes to the sign in page, whatever the redirect parameters say" do
    sign_in @alice
    get destroy_user_session_path, params: { redirect_to: "https://evil.example/" }

    assert_redirected_to new_user_session_path
  end
end
