# ステージングの初期データ。DB を初期化した後に、毎回、同じ内容を入れる。
#
#   - E2E 用ユーザー: ステージングの画面確認(ブラウザテスト)でログインするユーザー。
#                     メールとパスワードは、コードに書かず、呼び出し元(db/seeds.rb)が環境変数から渡す。
#   - 別のユーザー  : 他人の記録が混ざらないことの確認用。ログインはできない(パスワードは捨てる)。
#   - 記録          : E2E 用ユーザーに 27 件(1 ページ 25 件のため、2 ページに分かれる)、別のユーザーに 1 件。
#                     日付は固定。同じ店が複数回あり、統計の集計も確認できる。
#
# 何度実行しても同じ結果になる(この 2 ユーザーの記録だけを作り直す。他のユーザーには触れない)。
class StagingSeed
  OTHER_EMAIL = "other@example.com".freeze

  # [店, 場所]。27 件を、この順に繰り返して割り当てる(6・6・5・5・5 件)
  SHOPS = [
    [ "Ramen Taro", "Tokyo" ],
    [ "Curry House", "Osaka" ],
    [ "Sushi Bar", "Kyoto" ],
    [ "Soba Hanako", "Nagano" ],
    [ "Pizza Pronto", "Yokohama" ]
  ].freeze

  # 登録画面のラジオボタンの値(#75 で、編集画面と揃える方針が決まるまでは、登録画面に合わせる)
  USECASES = %w[shop home take_out delivery].freeze
  EAT_WITHS = %w[self friends family].freeze
  EAT_TIMES = %w[morning lunch dinner].freeze

  MAIN_RECORD_COUNT = 27
  START_DATE = Date.new(2025, 1, 1)

  def self.run(email:, password:)
    new(email: email, password: password).run
  end

  def initialize(email:, password:)
    @email = email.to_s
    @password = password.to_s
    raise ArgumentError, "email is blank" if @email.strip.empty?
    raise ArgumentError, "password is blank" if @password.empty?
  end

  def run
    ActiveRecord::Base.transaction do
      main = upsert_user(@email, @password, "e2e")
      other = upsert_user(OTHER_EMAIL, SecureRandom.hex(16), "other")
      [ main, other ].each { |user| user.eat_records.destroy_all }
      MAIN_RECORD_COUNT.times { |i| create_record(main, i) }
      create_record(other, 0)
    end
  end

  private

  def upsert_user(email, password, username)
    user = User.find_or_initialize_by(email: email)
    user.username = username
    user.password = password
    user.save!
    user
  end

  def create_record(user, index)
    shop, place = SHOPS[index % SHOPS.size]
    user.eat_records.create!(
      shop_name: shop,
      place_name: place,
      usecase: USECASES[index % USECASES.size],
      eat_with: EAT_WITHS[index % EAT_WITHS.size],
      eat_time: EAT_TIMES[index % EAT_TIMES.size],
      eat_date: START_DATE + (index * 7),
      eat_menu: "Seed menu #{index + 1}"
    )
  end
end
