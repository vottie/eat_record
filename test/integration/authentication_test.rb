require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "sign in and sign up pages render" do
    signup_open!
    get new_user_session_path
    assert_response :success

    get new_user_registration_path
    assert_response :success
  end

  test "sign in with the right password redirects to the index" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "password123" } }
    follow_redirect!

    assert_response :success
    assert_select "a", text: "alice"
  end

  test "sign in with a wrong password is rejected" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "wrong-password" } }

    # 失敗時の再表示のステータスは Devise / Rails の版で 200 と 422 の差がある
    assert_includes [200, 422], response.status
    get eat_records_path
    assert_redirected_to new_user_session_path
  end
end
