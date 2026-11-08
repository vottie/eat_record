require "test_helper"

# 新規登録(Devise の registrations + ウェルカムメール)
class RegistrationTest < ActionDispatch::IntegrationTest
  def sign_up_params(overrides = {})
    { user: { username: "newbie", email: "newbie@example.com",
              password: "password123", password_confirmation: "password123" }.merge(overrides) }
  end

  test "sign up creates the user, signs in and sends the welcome mail" do
    assert_difference("User.count", 1) do
      assert_emails 1 do
        post user_registration_path, params: sign_up_params
      end
    end

    assert_redirected_to eat_records_path
    user = User.find_by!(email: "newbie@example.com")
    assert_equal "newbie", user.username

    follow_redirect!
    assert_response :success
    assert_select "a", text: "newbie"

    mail = ActionMailer::Base.deliveries.last
    assert_equal ["newbie@example.com"], mail.to
    assert_equal ["noreply@example.com"], mail.from
  end

  # 不正な入力は、フォームを再表示する(このアプリは 200 で返す。Rails / Devise の既定の変更で 422 になる場合は、ここで検出する)
  test "sign up is rejected for invalid input and creates no user" do
    {
      "an email that is already taken" => { email: users(:alice).email },
      "a password confirmation that does not match" => { password_confirmation: "different" },
      "a password that is too short" => { password: "short", password_confirmation: "short" },
      "an email without @" => { email: "not-an-email" }
    }.each do |label, overrides|
      assert_no_difference("User.count", "sign up with #{label}") do
        post user_registration_path, params: sign_up_params(overrides)
      end
      assert_response :success, "sign up with #{label}"
    end
  end

  test "a signed up user can sign in again with the password" do
    post user_registration_path, params: sign_up_params
    delete_session
    post user_session_path, params: { user: { email: "newbie@example.com", password: "password123" } }

    assert_redirected_to eat_records_path
  end

  private

  def delete_session
    get destroy_user_session_path
  end
end
