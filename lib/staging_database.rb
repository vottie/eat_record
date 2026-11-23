# ステージング DB を初期化してよいかを確かめる守り。
#
# 初期化(DB の削除・再作成)は、ステージングの DB にだけ許す。次の 2 つを、両方満たさないときは、何もせず中止する。
#   1. Rails の環境が staging である
#   2. DB 名が、_stg で終わる(本番の DB 名は、_stg で終わらない)
#
# 公開リポジトリのため、中止の理由には、DB 名などの実際の値を含めない(Actions のログに残るため)。
module StagingDatabase
  class Unsafe < StandardError; end

  SUFFIX = "_stg".freeze

  def self.ensure_safe!(rails_env: Rails.env, database: configured_database(rails_env))
    unless rails_env.to_s == "staging"
      raise Unsafe, "Refusing to reset the database: the Rails environment is not staging."
    end
    unless database.to_s.end_with?(SUFFIX)
      raise Unsafe, "Refusing to reset the database: the database name does not end with #{SUFFIX}."
    end
  end

  # database.yml の、その環境の DB 名(接続はしない)
  def self.configured_database(rails_env)
    Rails.configuration.database_configuration.dig(rails_env.to_s, "database")
  end
end
