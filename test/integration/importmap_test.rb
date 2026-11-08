require "test_helper"

# application.js の import が importmap に解決できないと、application.js 全体が実行されず、
# Turbo と Bootstrap の JS が動かなくなる(Issue #26)。ブラウザを使わずに、その食い違いを検出する。
class ImportmapTest < ActionDispatch::IntegrationTest
  test "every import in application.js resolves in the importmap" do
    source = File.read(Rails.root.join("app/javascript/application.js"))
    imported = source.scan(/^\s*import\s+(?:[^"';]+?\s+from\s+)?["']([^"']+)["']/).flatten

    resolved = JSON.parse(
      Rails.application.importmap.to_json(resolver: ApplicationController.helpers)
    ).fetch("imports").keys

    assert_not_empty imported
    assert_empty imported - resolved, "application.js が import しているが importmap に無い: #{(imported - resolved).join(', ')}"
  end
end
