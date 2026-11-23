# ステージングの DB を、固定の初期データに戻す(#33)。
#
#   bundle exec cap staging db:reset
#
# 本番では、実行できない(ここで中止する。サーバー側の staging:reset にも、同じ守りがある)。
# E2E 用ユーザーのメールとパスワードは、サーバーの .env から読む(db/seeds.rb を参照)。
namespace :db do
  desc "Reset the staging database to the fixed seed data (staging only)"
  task :reset do
    unless fetch(:stage).to_s == "staging"
      raise "db:reset runs only on the staging stage."
    end

    on roles(:db) do
      within current_path do
        with rails_env: "staging" do
          execute :rake, "staging:reset"
        end
      end
    end

    # スキーマを作り直したため、Puma を再起動する(古いスキーマのキャッシュを残さない)
    invoke "puma:restart"
  end
end
