require "test_helper"

# 新規登録は、既定で閉じている(環境変数 ALLOW_SIGNUP=1 のときだけ開く)。
# 閉じていても、既存のユーザーのログインは、これまでどおり。
class SignupClosedTest < ActionDispatch::IntegrationTest
  CLOSED_NOTICE = "現在、新規登録は受け付けていません。".freeze

  def sign_up_params
    { user: { username: "newbie", email: "newbie@example.com", password: "password123", password_confirmation: "password123" } }
  end

  def mock_google(uid: "g-new", email: "newcomer@example.com", name: "Newcomer")
    OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid, info: { email: email, name: name })
  end

  def with_omniauth_test_mode(auth)
    OmniAuth.config.test_mode = true
    OmniAuth.config.logger = Logger.new(nil)
    OmniAuth.config.mock_auth[:google_oauth2] = auth
    yield
  ensure
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  test "sign up is closed by default" do
    assert_nil ENV["ALLOW_SIGNUP"]

    get new_user_registration_path

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "p.notice", text: CLOSED_NOTICE
  end

  test "posting a sign up while closed creates no user and sends no mail" do
    assert_no_difference("User.count") do
      assert_no_emails do
        post user_registration_path, params: sign_up_params
      end
    end

    assert_redirected_to new_user_session_path
  end

  test "only ALLOW_SIGNUP=1 opens sign up" do
    ["0", "", "true", "yes"].each do |value|
      ENV["ALLOW_SIGNUP"] = value
      get new_user_registration_path
      assert_redirected_to new_user_session_path, "ALLOW_SIGNUP=#{value.inspect} は閉じたまま"
    end

    signup_open!
    get new_user_registration_path
    assert_response :success
  end

  test "the sign in page has no Sign up link while closed, and has one when open" do
    get new_user_session_path
    assert_response :success
    assert_select "a", text: "Sign up", count: 0

    signup_open!
    get new_user_session_path
    assert_select "a", text: "Sign up", count: 1
  end

  test "existing users can still sign in and manage their account while closed" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "password123" } }
    assert_redirected_to eat_records_path

    get edit_user_registration_path
    assert_response :success
  end

  test "a Google sign in of an unknown user creates no user while closed" do
    with_omniauth_test_mode(mock_google) do
      assert_no_difference("User.count") do
        get "/users/auth/google_oauth2/callback"
      end

      assert_redirected_to new_user_session_path
      follow_redirect!
      assert_select "p.notice", text: CLOSED_NOTICE
      get eat_records_path
      assert_redirected_to new_user_session_path
    end
  end

  test "a Google sign in of an existing user still works while closed" do
    existing = User.create!(email: "known@example.com", username: "known", password: "password123", provider: "google_oauth2", uid: "g-known")

    with_omniauth_test_mode(mock_google(uid: "g-known", email: "known@example.com", name: "Known")) do
      assert_no_difference("User.count") do
        get "/users/auth/google_oauth2/callback"
      end

      assert_redirected_to eat_records_path
      follow_redirect!
      assert_response :success
      assert_select "a", text: existing.username
    end
  end
end
