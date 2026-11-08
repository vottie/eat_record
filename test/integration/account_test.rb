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

  test "nothing is changed when the current password is wrong" do
    sign_in @user
    put user_registration_path, params: { user: { email: "changed@example.com", username: "changed", current_password: "WRONG-password" } }

    @user.reload
    assert_equal "alice@example.com", @user.email
    assert_equal "alice", @user.username
  end

  test "attributes that are not account fields are ignored" do
    sign_in @user
    hash = BCrypt::Password.create("chosen-elsewhere")
    put user_registration_path, params: { user: { username: "alice", current_password: "password123",
                                                  encrypted_password: hash, provider: "google_oauth2", uid: "other-uid",
                                                  reset_password_token: "token" } }

    @user.reload
    assert @user.valid_password?("password123")
    assert_not @user.valid_password?("chosen-elsewhere")
    assert_nil @user.provider
    assert_nil @user.uid
    assert_nil @user.reset_password_token
  end

  test "deleting an account removes the user and their records, and signs out" do
    user = users(:bob)
    sign_in user
    own_records = EatRecord.where(user_id: user.id).count
    assert_operator own_records, :>, 0

    assert_difference("User.count", -1) do
      assert_difference("EatRecord.count", -own_records) do
        delete user_registration_path
      end
    end
    assert_not User.exists?(user.id)
    assert_equal 3, EatRecord.where(user_id: @user.id).count, "ほかのユーザーの記録は消えない"
    get eat_records_path
    assert_redirected_to new_user_session_path
  end

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
