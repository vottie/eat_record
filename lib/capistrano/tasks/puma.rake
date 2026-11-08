# Puma は systemd(puma.service)で動いているため、デプロイ後に systemctl で再起動する。
# サーバ側で、デプロイユーザに次の 1 コマンドだけパスワードなしの sudo を許可しておくこと:
#   <user> ALL=(root) NOPASSWD: /usr/bin/systemctl restart puma.service
# sudo -n はパスワードを聞かず、許可が無ければ失敗する(デプロイが止まらないまま黙って古い Puma が残る事態を防ぐ)。
namespace :puma do
  desc "Restart Puma via systemd"
  task :restart do
    on roles(:app) do
      execute :sudo, "-n", "/usr/bin/systemctl", "restart", fetch(:puma_service, "puma.service")
    end
  end
end

# symlink:release の後(新しいリリースが current になった後)に再起動する
after "deploy:published", "puma:restart"
