namespace :staging do
  desc "Reset the staging database (drop, create, load schema, seed). Refuses to run anywhere else."
  task reset: :environment do
    # 守りを通らなければ、何も削除せずに中止する(db:reset は、この後に呼ぶ)
    StagingDatabase.ensure_safe!
    Rake::Task["db:reset"].invoke
  end
end
