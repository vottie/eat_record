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

  test "from_omniauth with create: false does not create a user" do
    auth = OmniAuth::AuthHash.new(
      provider: "google_oauth2", uid: "no-such-uid",
      info: { email: "nobody@example.com", name: "Nobody" }
    )

    assert_no_difference("User.count") do
      assert_nil User.from_omniauth(auth, create: false)
    end
  end

  test "from_omniauth with create: false returns the existing user" do
    existing = User.create!(email: "g@example.com", username: "g", password: "password123", provider: "google_oauth2", uid: "uid-1")
    auth = OmniAuth::AuthHash.new(provider: "google_oauth2", uid: "uid-1", info: { email: "g@example.com", name: "G" })

    assert_equal existing, User.from_omniauth(auth, create: false)
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

  def build_user(overrides = {})
    User.new({ email: "new@example.com", password: "password123", password_confirmation: "password123", username: "newbie" }.merge(overrides))
  end

  def google_auth(uid: "g-1", email: "g1@example.com", name: "G One")
    OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid, info: { email: email, name: name })
  end

  test "email is stored in lower case without surrounding spaces" do
    user = build_user(email: "  New@Example.COM ")
    user.save!

    assert_equal "new@example.com", user.reload.email
  end

  test "email must be present and well formed" do
    [ "", "not-an-email", "a@", "@example.com" ].each do |email|
      user = build_user(email: email)

      assert_not user.valid?, "#{email.inspect} は無効のはず"
      assert user.errors.key?(:email), email.inspect
    end
  end

  test "email uniqueness ignores case" do
    user = build_user(email: users(:alice).email.upcase)

    assert_not user.valid?
    assert user.errors.of_kind?(:email, :taken)
  end

  test "password length is limited to 6..128" do
    assert_not build_user(password: "a" * 5, password_confirmation: "a" * 5).valid?
    assert build_user(password: "a" * 6, password_confirmation: "a" * 6).valid?
    assert build_user(password: "a" * 128, password_confirmation: "a" * 128).valid?
    assert_not build_user(password: "a" * 129, password_confirmation: "a" * 129).valid?
  end

  test "password confirmation must match" do
    user = build_user(password_confirmation: "different")

    assert_not user.valid?
    assert user.errors.of_kind?(:password_confirmation, :confirmation)
  end

  test "password is stored as a hash and can be checked" do
    user = build_user
    user.save!

    assert_not_equal "password123", user.encrypted_password
    assert user.valid_password?("password123")
    assert_not user.valid_password?("wrong")
  end

  test "destroying a user destroys their records and leaves other users' records" do
    alice = users(:alice)

    assert_difference("EatRecord.count", -3) { alice.destroy }
    assert_equal 1, EatRecord.where(user_id: users(:bob).id).count
  end

  test "eat_records returns only the user's own records" do
    assert_equal 3, users(:alice).eat_records.count
    assert_equal [ "Sushi Bar" ], users(:bob).eat_records.map(&:shop_name)
  end

  test "from_omniauth stores the provider and uid, and the user cannot sign in with a password" do
    user = User.from_omniauth(google_auth)

    assert user.persisted?
    assert_equal "google_oauth2", user.provider
    assert_equal "g-1", user.uid
    assert_not user.valid_password?("")
    assert_not user.valid_password?("password123")
  end

  test "from_omniauth keeps users of different uids apart" do
    first = User.from_omniauth(google_auth(uid: "g-1", email: "g1@example.com"))
    second = User.from_omniauth(google_auth(uid: "g-2", email: "g2@example.com"))

    assert_not_equal first, second
    assert_equal first, User.from_omniauth(google_auth(uid: "g-1", email: "g1@example.com"))
  end

  # 既にパスワードで登録されているメールアドレスの Google ログインは、その利用者としてログインさせない
  test "from_omniauth does not take over an existing user with the same email" do
    alice = users(:alice)

    result = nil
    assert_no_difference("User.count") do
      result = User.from_omniauth(google_auth(uid: "g-alice", email: alice.email, name: "Alice G"))
    end

    assert_not result.persisted?
    assert_nil alice.reload.provider
    assert_nil alice.uid
  end
end
