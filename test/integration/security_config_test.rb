require "test_helper"

# 設定(#69)。意図しない変更(cookie の属性、ヘッダー、ログに出さないパラメータ)を検知する。
# 本番だけの設定(force_ssl など)は、テスト環境では確認できないため、対象外。
class SecurityConfigTest < ActionDispatch::IntegrationTest
  test "sensitive parameters are filtered from the logs" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    filtered = filter.filter(
      "password" => "p1", "password_confirmation" => "p2", "current_password" => "p3",
      "reset_password_token" => "t1", "authenticity_token" => "t2", "secret" => "s1", "otp" => "o1",
      "shop_name" => "kept"
    )

    filtered.except("shop_name").each { |key, value| assert_equal "[FILTERED]", value, "#{key} がログに出る" }
    assert_equal "kept", filtered["shop_name"]
  end

  test "the session cookie is HttpOnly and SameSite" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "password123" } }

    cookie = Array(response.headers["Set-Cookie"]).join("\n").lines.find { |line| line.start_with?("_my_session=") }
    assert cookie, "セッションの cookie が、設定されていない"
    assert_match(/;\s*httponly/i, cookie)
    assert_match(/;\s*samesite=(lax|strict)/i, cookie)
  end

  test "the default security headers are sent" do
    get new_user_session_path

    assert_equal "SAMEORIGIN", response.headers["X-Frame-Options"]
    assert_equal "nosniff", response.headers["X-Content-Type-Options"]
    assert_equal "strict-origin-when-cross-origin", response.headers["Referrer-Policy"]
  end

  test "passwords are stored as hashes" do
    user = users(:alice)

    assert_not_equal "password123", user.encrypted_password
    assert_match(/\A\$2[aby]\$/, user.encrypted_password)
    assert_nil user.attributes["password"]
  end

  test "a wrong password and an unknown email are rejected in the same way" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "wrong-password" } }
    wrong_password = [ response.status, response.location ]

    post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong-password" } }
    unknown_email = [ response.status, response.location ]

    assert_equal wrong_password, unknown_email
  end

  # テスト環境では、CSRF の検証を切ってある。ここでだけ有効にして、トークンなしの操作が通らないことを確認する
  test "deleting an account without a CSRF token is not accepted" do
    post user_session_path, params: { user: { email: users(:alice).email, password: "password123" } }

    with_forgery_protection do
      assert_no_difference("User.count") do
        begin
          delete user_registration_path
        rescue ActionController::InvalidAuthenticityToken
          # 例外で拒否する設定でも、ユーザーは削除されない
        end
      end
    end
    assert User.exists?(users(:alice).id)
  end

  private

  def with_forgery_protection
    before = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = before
  end
end
