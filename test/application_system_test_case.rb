require "test_helper"

# ブラウザの自動テスト(システムテスト)の共通設定。
#
#   HEADLESS=0      ブラウザを表示する(Mac のデバッグ用)。未指定なら、ヘッドレス
#   E2E_BASE_URL    指定すると、そのサーバー(ステージング)へ接続する。未指定なら、Rails の内蔵サーバーと fixtures
#   E2E_EMAIL / E2E_PASSWORD
#                   E2E_BASE_URL を指定したときの、ログイン用のテストユーザー
if ENV["E2E_BASE_URL"].to_s.strip != ""
  Capybara.run_server = false
  Capybara.app_host = ENV["E2E_BASE_URL"].strip
  Capybara.default_max_wait_time = 10
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # 画面幅(デスクトップ / スマホ)
  SCREEN_SIZES = { desktop: [1400, 1400], mobile: [375, 812] }.freeze

  # Chrome で、画面幅を指定して実行する。HEADLESS=0 以外は、ヘッドレス。
  def self.use_chrome(screen)
    browser = ENV["HEADLESS"] == "0" ? :chrome : :headless_chrome
    driven_by :selenium, using: browser, screen_size: SCREEN_SIZES.fetch(screen) do |options|
      # ブラウザのコンソールの出力(JS の読み込みエラーなど)を、取得できるようにする
      options.logging_prefs = { browser: "ALL" }
      # 実行環境(GitHub Actions など、root で動く Linux のコンテナ)用
      if ENV["CI"].present?
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
      end
    end
  end
end
