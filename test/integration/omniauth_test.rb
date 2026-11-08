require "test_helper"

# Google ログイン(OmniAuth)。Google との通信は行わず、開始の動作と、コールバックの処理を確認する。
class OmniauthTest < ActionDispatch::IntegrationTest
  GOOGLE_PATH = "/users/auth/google_oauth2".freeze

  def mock_google(uid: "g-123", email: "google@example.com", name: "Google User")
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

  def with_forgery_protection
    old = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = old
  end

  test "the sign in page offers Google sign in" do
    get new_user_session_path

    assert_response :success
    assert_select "form[action=?][method=post]", GOOGLE_PATH
  end

  test "starting Google sign in with a CSRF token redirects to Google" do
    with_forgery_protection do
      get new_user_session_path
      token = css_select("meta[name=csrf-token]").first["content"]
      post GOOGLE_PATH, params: { authenticity_token: token }

      assert_response :redirect
      assert_match %r{\Ahttps://accounts\.google\.com/}, response.location
    end
  end

  test "starting Google sign in without a CSRF token is rejected" do
    with_forgery_protection do
      post GOOGLE_PATH

      assert_response :unprocessable_entity
    end
  end

  test "starting Google sign in with GET does not redirect to Google" do
    get GOOGLE_PATH

    assert_no_match(/accounts\.google\.com/, response.location.to_s)
  end

  test "the callback creates the user on first sign in and signs in" do
    signup_open!
    with_omniauth_test_mode(mock_google) do
      assert_difference("User.count", 1) do
        get "#{GOOGLE_PATH}/callback"
      end

      assert_redirected_to eat_records_path
      user = User.find_by!(email: "google@example.com")
      assert_equal ["google_oauth2", "g-123", "Google User"], [user.provider, user.uid, user.username]

      follow_redirect!
      assert_response :success
      assert_select "a", text: "Google User"
    end
  end

  test "the callback signs in the existing user without creating another" do
    signup_open!
    with_omniauth_test_mode(mock_google) do
      get "#{GOOGLE_PATH}/callback"
      get destroy_user_session_path

      assert_no_difference("User.count") do
        get "#{GOOGLE_PATH}/callback"
      end
      assert_redirected_to eat_records_path
    end
  end

  test "a failed callback does not sign in and goes to the top page" do
    with_omniauth_test_mode(:invalid_credentials) do
      assert_no_difference("User.count") do
        get "#{GOOGLE_PATH}/callback"
      end

      assert_redirected_to root_path
      get eat_records_path
      assert_redirected_to new_user_session_path
    end
  end
end
