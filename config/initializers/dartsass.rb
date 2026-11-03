# Bootstrap 5.3 は Sass の @import 等を使うため、Dart Sass の非推奨警告が大量に出る。
# 依存ライブラリ由来の警告と @import の警告だけを抑える(ビルドの結果は変わらない)。
Rails.application.config.dartsass.build_options << "--quiet-deps" << "--silence-deprecation=import"
