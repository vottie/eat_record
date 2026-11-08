ENV["RAILS_ENV"] ||= "test"
# メールの送信元は、本番では .env の値を使う。テストでは .env を読み込まないため、固定値を与える
# (NotificationMailer と Devise のメーラーが、読み込み時に参照する)。
ENV["WELCOME_MAILER_ADDRESS"] ||= "noreply@example.com"
require_relative "../config/environment"
require "rails/test_help"

# テスト環境では、ルーティングが最初のリクエストまで読み込まれない(遅延読み込み)。
# OmniAuth のパス(Devise が、ルーティングの読み込み時に設定する)や、メール本文の URL が、
# テストの実行順序によって失敗しないよう、先に読み込んでおく。
Rails.application.reload_routes_unless_loaded

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

# 環境の読み込みが、上の ENV の設定より先に行われる実行(テスト全体を並列で動かす場合など)でも、
# Devise の送信元が nil にならないよう、読み込み後にも明示的に設定する。
Devise.mailer_sender = ENV.fetch("WELCOME_MAILER_ADDRESS")

# メール本文の URL(パスワード再設定のリンクなど)に必要なホスト
ActionMailer::Base.default_url_options = { host: "example.com" }

class ActionDispatch::IntegrationTest
  # sign_in / sign_out を統合テストで使う
  include Devise::Test::IntegrationHelpers

  # 新規登録は、既定で閉じている(環境変数 ALLOW_SIGNUP=1 で開く)。テストごとに元の値へ戻す。
  setup { @signup_env_before = ENV["ALLOW_SIGNUP"] }
  teardown { @signup_env_before.nil? ? ENV.delete("ALLOW_SIGNUP") : ENV["ALLOW_SIGNUP"] = @signup_env_before }

  def signup_open!(open = true)
    open ? ENV["ALLOW_SIGNUP"] = "1" : ENV.delete("ALLOW_SIGNUP")
  end
end
