# GitHub Actions(deploy.yml)が、config/deploy/<環境>.rb として使う Capistrano の設定。
# このリポジトリは公開のため、ホスト名・ユーザー名などは、ここに書かず、環境変数(GitHub の Secrets / Variables)から読む。
# 手元(Mac)からのデプロイは、これまでどおり、Git 対象外の config/deploy/{staging,production}.rb を使う。

stage = ENV.fetch("DEPLOY_STAGE")
user  = ENV.fetch("DEPLOY_USER")

server ENV.fetch("DEPLOY_HOST"),
  user: user,
  roles: %w{app db web},
  port: Integer(ENV.fetch("DEPLOY_PORT", "22")),
  ssh_options: {
    user: user,
    keys: [File.expand_path("~/.ssh/deploy_key")],
    keys_only: true,
    forward_agent: false,
    auth_methods: %w(publickey),
    verify_host_key: :always # ~/.ssh/known_hosts に、固定したホスト鍵が入っている
  }

if stage == "staging"
  # OCI は rbenv をユーザー領域に入れている(deploy.rb の system /opt/rbenv を上書きする)
  set :rbenv_type, :user
  set :rbenv_path, "/home/#{user}/.rbenv"
  set :rails_env, "staging"
end
