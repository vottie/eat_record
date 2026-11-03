require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "fixture user is valid" do
    assert users(:alice).valid?
  end

  test "email must be unique" do
    user = User.new(email: users(:alice).email, password: "password123", username: "dup")

    assert_not user.valid?
    assert user.errors.of_kind?(:email, :taken)
  end

  test "from_omniauth creates a user on first sign in" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "12345",
      info: { email: "google@example.com", name: "Google User" }
    )

    user = nil
    assert_difference("User.count", 1) { user = User.from_omniauth(auth) }
    assert_equal "google@example.com", user.email
    assert_equal "Google User", user.username
  end

  test "from_omniauth returns the existing user on later sign ins" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "12345",
      info: { email: "google@example.com", name: "Google User" }
    )
    first = User.from_omniauth(auth)

    assert_no_difference("User.count") do
      assert_equal first, User.from_omniauth(auth)
    end
  end
end
