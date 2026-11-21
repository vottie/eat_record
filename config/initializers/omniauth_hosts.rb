# OmniAuth は、Google へ渡すコールバック URL を、リクエストの Host ヘッダーから作る。
# nginx は、どんな Host のリクエストも Rails に渡すため、偽装された Host で URL を作らせない。
#
# 本番・ステージングでは、アプリのホスト(環境変数 HOST。セッションの Cookie のドメインにも使っている)と、
# そのサブドメインのリクエストだけを受け付ける。HOST が空の環境(開発・テスト)では、制限しない。
module OmniauthHosts
  # host の完全一致と、そのサブドメインに一致する正規表現。例: "example.net" → example.net, www.example.net
  # (「evilexample.net」や「example.net.evil.com」には、一致しない)
  def self.allowed(host)
    return nil if host.to_s.strip.empty?

    [/(?:[a-z0-9-]+\.)*#{Regexp.escape(host.strip)}/i]
  end
end

if Rails.env.production? || Rails.env.staging?
  OmniAuth.config.allowed_hosts = OmniauthHosts.allowed(ENV["HOST"])
end
