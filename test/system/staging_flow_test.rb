require "application_system_test_case"
require "support/step_report"

# ステージングの画面確認(ログイン → 登録 → 編集 → 削除 → ログアウト)を、ブラウザで自動実行する。
# 1 つの画面幅につき、S1〜S9 を 1 本の流れとして順番に実行する(S4 で作った記録を、S5〜S8 で使うため)。
#
#   bin/rails test:system                          Rails の内蔵サーバー + fixtures(alice)で実行
#   HEADLESS=0 bin/rails test:system               ブラウザを表示して実行
#   E2E_BASE_URL=http://localhost:3000 E2E_EMAIL=... E2E_PASSWORD=... bin/rails test:system
#                                                  指定したサーバー(ステージング)に対して実行
module StagingFlow
  RECORD_PREFIX = "E2E-".freeze

  private

  def external?
    ENV["E2E_BASE_URL"].to_s.strip != ""
  end

  def e2e_email
    external? ? ENV.fetch("E2E_EMAIL") : users(:alice).email
  end

  def e2e_password
    external? ? ENV.fetch("E2E_PASSWORD") : "password123"
  end

  def screen_name
    self.class::SCREEN
  end

  # ステップを実行し、結果と時間を記録する。失敗したら、記録してから、そのまま失敗にする。
  def step(id, name)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    check_console(id, name, started)
    StepReport.record(screen: screen_name, id: id, name: name, result: "成功", seconds: elapsed(started))
  rescue Minitest::Assertion, StandardError => e
    StepReport.record(screen: screen_name, id: id, name: name, result: "失敗", seconds: elapsed(started), message: e.message)
    raise
  end

  def elapsed(started)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  end

  # C1: ブラウザのコンソールに、JS の読み込みエラーなど(SEVERE)が無いこと
  def check_console(id, name, started)
    errors = console_errors
    return if errors.empty?
    raise Minitest::Assertion, "コンソールにエラー(#{id} #{name}): #{errors.first(2).join(' / ')}"
  end

  # 既知で、今回の対象外のもの(無視する)。
  #   favicon: アイコンが無いだけ
  #   /eat_records/manifest: PWA のマニフェストが、ログインを要求するため、未ログインの画面では JSON として読めない
  #   Form responses must redirect: ログインに失敗したとき、Devise が 200 で画面を返すため、Turbo が表示を捨てる
  #                                 (エラーメッセージが出ない。既知の不具合。直すまで、無視する)
  IGNORED_CONSOLE = [/favicon/, %r{/eat_records/manifest}, /Form responses must redirect/].freeze

  def console_errors
    logs = page.driver.browser.logs.get(:browser)
    logs.select { |l| l.level == "SEVERE" }.map(&:message).reject { |m| IGNORED_CONSOLE.any? { |re| m.match?(re) } }
  rescue StandardError
    []
  end

  # C2: スマホ幅で、横スクロールが出ないこと(警告として記録するだけ。失敗にしない)
  def check_horizontal_scroll
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    overflow = page.evaluate_script("document.documentElement.scrollWidth > window.innerWidth")
    StepReport.record(screen: screen_name, id: "C2", name: "横スクロールが出ない",
                      result: overflow ? "警告" : "成功", seconds: elapsed(started),
                      message: overflow ? "ページが画面幅より広い" : nil)
  end

  def login_as_test_user(password = e2e_password)
    visit "/users/sign_in"
    fill_in "user_email", with: e2e_email
    fill_in "user_password", with: password
    click_button "Log in"
  end

  # 前回の実行が途中で失敗して、残った記録(E2E- で始まる)を、画面から削除する
  def delete_leftover_records
    10.times do
      visit "/eat_records"
      link = first(:link, text: /\A#{RECORD_PREFIX}/, minimum: 0)
      break unless link
      link.click
      accept_confirm { click_on "削除" }
      assert_no_selector "h3", text: /お店の名前/
    end
  end

  def pick_radio(name, value)
    find("input[type='radio'][name='eat_record[#{name}]'][value='#{value}']").click
  end

  def submit_record_form
    find("form[action^='/eat_records'] input[type='submit']").click
  end

  public

  def run_flow
    shop = "#{RECORD_PREFIX}#{ENV.fetch('GITHUB_RUN_ID', Time.now.strftime('%Y%m%d%H%M%S'))}"

    step("S1", "ログイン画面を開く") do
      visit "/users/sign_in"
      assert_field "user_email"
      assert_field "user_password"
      assert_button "Log in"
    end

    step("S2", "ログインに失敗する") do
      login_as_test_user("wrong-#{SecureRandom.hex(4)}")
      assert_field "user_password"
      assert_no_text "ユーザ名:"
    end

    step("S3", "ログインする") do
      login_as_test_user
      assert_text "ユーザ名:"
      delete_leftover_records
    end

    step("S4", "記録を登録する") do
      visit "/eat_records"
      click_on "新たに登録"
      fill_in "eat_record_shop_name", with: shop
      fill_in "eat_record_place_name", with: "テスト区"
      # 登録画面のラジオボタンの値は、英語(shop / self / lunch)。編集画面は日本語(店 / 一人 / 昼)で、揃っていない
      pick_radio("usecase", "shop")
      pick_radio("eat_with", "self")
      pick_radio("eat_time", "lunch")
      fill_in "eat_record_eat_menu", with: "テスト定食"
      fill_in "eat_record_article", with: "自動テストで作成"
      submit_record_form
      assert_text "お店の名前: #{shop}"
      assert_text "テスト定食"
    end

    step("S5", "一覧に反映される") do
      click_on "戻る"
      assert_link shop
    end

    step("S6", "記録を編集する") do
      click_on shop
      click_on "編集"
      fill_in "eat_record_eat_menu", with: "テスト定食(更新)"
      submit_record_form
      assert_text "テスト定食(更新)"
    end

    step("S7", "通算の記録を見る") do
      click_on "戻る"
      click_on "通算の記録"
      assert_text shop
    end

    step("S8", "記録を削除する") do
      click_on "戻る"
      click_on shop
      accept_confirm { click_on "削除" }
      assert_no_link shop
    end

    step("S9", "ログアウトする") do
      click_on "ログアウト"
      # ログアウトの完了(ログイン画面への移動)を待ってから、一覧を直接開く(待たないと、処理中のログイン状態で一覧が開く)
      assert_current_path "/users/sign_in"
      visit "/eat_records"
      assert_current_path "/users/sign_in"
    end

    check_horizontal_scroll if screen_name == "スマホ"
  end
end

class DesktopStagingFlowTest < ApplicationSystemTestCase
  SCREEN = "デスクトップ".freeze
  use_chrome :desktop
  include StagingFlow

  test "ステージングの画面確認(デスクトップ)" do
    run_flow
  end
end

class MobileStagingFlowTest < ApplicationSystemTestCase
  SCREEN = "スマホ".freeze
  use_chrome :mobile
  include StagingFlow

  test "ステージングの画面確認(スマホ)" do
    run_flow
  end
end
