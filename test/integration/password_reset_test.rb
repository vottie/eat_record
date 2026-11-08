require "test_helper"

# パスワードの再設定(メールのリンクから)
class PasswordResetTest < ActionDispatch::IntegrationTest
  setup { @user = users(:alice) }

  def request_reset_for(email)
    post user_password_path, params: { user: { email: email } }
  end

  # メール本文のリンクから、再設定のトークンを取り出す
  def token_from(mail)
    mail.body.to_s[/reset_password_token=([^"&\s]+)/, 1]
  end

  test "the request page renders" do
    get new_user_password_path

    assert_response :success
  end

  test "requesting a reset sends a mail with a link to the user" do
    assert_emails 1 do
      request_reset_for(@user.email)
    end

    assert_redirected_to new_user_session_path
    mail = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], mail.to
    assert_equal ["noreply@example.com"], mail.from
    assert_not_nil token_from(mail), "メール本文に再設定のリンクがある"
  end

  test "requesting a reset for an unknown email sends no mail" do
    assert_no_emails do
      request_reset_for("nobody@example.com")
    end

    assert_response :success
  end

  test "the mailed token opens the form and sets a new password" do
    request_reset_for(@user.email)
    token = token_from(ActionMailer::Base.deliveries.last)

    get edit_user_password_path(reset_password_token: token)
    assert_response :success

    put user_password_path, params: { user: { reset_password_token: token, password: "newpass1234", password_confirmation: "newpass1234" } }
    assert_redirected_to eat_records_path
    assert @user.reload.valid_password?("newpass1234")
    assert_not @user.valid_password?("password123")
  end

  test "a token cannot be used twice" do
    request_reset_for(@user.email)
    token = token_from(ActionMailer::Base.deliveries.last)
    params = { user: { reset_password_token: token, password: "newpass1234", password_confirmation: "newpass1234" } }
    put user_password_path, params: params
    delete_session

    put user_password_path, params: params
    assert_response :success
  end

  test "an invalid token does not change the password" do
    put user_password_path, params: { user: { reset_password_token: "invalid-token", password: "newpass1234", password_confirmation: "newpass1234" } }

    assert_response :success
    assert @user.reload.valid_password?("password123")
  end

  test "an expired token does not change the password" do
    request_reset_for(@user.email)
    token = token_from(ActionMailer::Base.deliveries.last)
    @user.reload.update_column(:reset_password_sent_at, (Devise.reset_password_within + 1.minute).ago)

    put user_password_path, params: { user: { reset_password_token: token, password: "newpass1234", password_confirmation: "newpass1234" } }

    assert_response :success
    assert @user.reload.valid_password?("password123")
  end

  test "a new password that does not match the confirmation is rejected" do
    request_reset_for(@user.email)
    token = token_from(ActionMailer::Base.deliveries.last)

    put user_password_path, params: { user: { reset_password_token: token, password: "newpass1234", password_confirmation: "different" } }

    assert_response :success
    assert @user.reload.valid_password?("password123")
  end

  private

  def delete_session
    get destroy_user_session_path
  end
end
