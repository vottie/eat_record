# ステージングの初期データ(lib/staging_seed.rb)。ステージングの DB を初期化した後に、bin/rails db:seed で入る。
# それ以外の環境(開発・テスト・本番)では、何もしない。
#
# E2E 用ユーザーのメールとパスワードは、サーバーの .env に、次の名前で置く(コードには書かない)。
# GitHub の Environment「staging」の Secrets(STAGING_E2E_EMAIL / STAGING_E2E_PASSWORD)と、同じ値にする。
#   STAGING_E2E_EMAIL, STAGING_E2E_PASSWORD
if Rails.env.staging?
  StagingDatabase.ensure_safe!
  StagingSeed.run(
    email: ENV.fetch("STAGING_E2E_EMAIL"),
    password: ENV.fetch("STAGING_E2E_PASSWORD")
  )
end
