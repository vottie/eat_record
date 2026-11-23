require "test_helper"

# Google ログインのコールバックの細かい分岐(omniauth_test.rb と signup_closed_test.rb で扱わないもの)
class OmniauthCallbackTest < ActionDispatch::IntegrationTest
  def mock_google(uid:, email:, name: "Someone")
    OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid, info: { email: email, name: name },
                           extra: { raw_info: { sub: uid } })
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

  # Google への開始用のパスは POST だけ。GET で開いた場合は、ルーティングの 404 で終わる(Google へは移動しない)
  test "opening the Google sign in path with GET is a 404" do
    get "/users/auth/google_oauth2"

    assert_response :not_found
  end

  # メールアドレスが、パスワードで登録済みの利用者と同じ場合、その利用者としてはログインせず、新しい利用者も作らない
  test "a Google sign in with the email of a password user does not sign in as that user" do
    signup_open!
    alice = users(:alice)

    with_omniauth_test_mode(mock_google(uid: "g-alice", email: alice.email, name: "Alice G")) do
      assert_no_difference("User.count") do
        get "/users/auth/google_oauth2/callback"
      end
    end

    assert_redirected_to new_user_registration_url
    assert_nil alice.reload.uid
    get eat_records_path
    assert_redirected_to new_user_session_path
  end

  test "the data of a Google sign in that could not create a user is kept in the session without the extra data" do
    signup_open!

    with_omniauth_test_mode(mock_google(uid: "g-alice", email: users(:alice).email)) do
      get "/users/auth/google_oauth2/callback"
    end

    data = session["devise.google_data"]
    assert data
    assert_equal "g-alice", data["uid"]
    assert_not data.key?("extra")
  end

  test "a Google sign in sets the success notice" do
    signup_open!

    with_omniauth_test_mode(mock_google(uid: "g-new", email: "newcomer@example.com")) do
      get "/users/auth/google_oauth2/callback"
    end
    follow_redirect!

    assert_response :success
    assert_select "p.notice", minimum: 1
  end
end
