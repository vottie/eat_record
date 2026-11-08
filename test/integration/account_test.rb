require "test_helper"

# サインアウトと、アカウントの編集・削除
class AccountTest < ActionDispatch::IntegrationTest
  setup { @user = users(:alice) }

  test "sign out ends the session and returns to the sign in page" do
    sign_in @user
    get destroy_user_session_path

    assert_redirected_to new_user_session_path
    get eat_records_path
    assert_redirected_to new_user_session_path
  end

  test "the account edit page requires signing in" do
    get edit_user_registration_path

    assert_redirected_to new_user_session_path
  end

  test "the account edit page renders when signed in" do
    sign_in @user
    get edit_user_registration_path

    assert_response :success
    assert_select "input[name='user[username]'][value=?]", @user.username
  end

  test "the username can be changed with the current password" do
    sign_in @user
    put user_registration_path, params: { user: { username: "alice2", current_password: "password123" } }

    assert_response :redirect
    assert_equal "alice2", @user.reload.username
  end

  test "the password can be changed with the current password" do
    sign_in @user
    put user_registration_path, params: { user: { password: "newpass1234", password_confirmation: "newpass1234", current_password: "password123" } }

    assert_response :redirect
    assert @user.reload.valid_password?("newpass1234")
  end

  test "the password is not changed when the current password is wrong" do
    sign_in @user
    put user_registration_path, params: { user: { password: "newpass1234", password_confirmation: "newpass1234", current_password: "WRONG-password" } }

    assert @user.reload.valid_password?("password123")
    assert_not @user.valid_password?("newpass1234")
  end

  # 記録を持つユーザーの削除は、外部キー(eat_records.user_id)のため失敗する(既知の不具合。ここでは対象にしない)。
  test "deleting an account without records removes the user and signs out" do
    user = User.create!(email: "leaving@example.com", username: "leaving", password: "password123")
    sign_in user

    assert_difference("User.count", -1) do
      delete user_registration_path
    end
    assert_not User.exists?(user.id)
    get eat_records_path
    assert_redirected_to new_user_session_path
  end
end
