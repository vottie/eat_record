require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Eatlog
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # load_defaults 7.0 の to_time_preserves_timezone(:offset)は、Rails 8.1 で :zone に変わる旨の非推奨警告が出る。
    # この設定は初期化ファイル(config/initializers)より前に反映されるため、ここで指定する。
    # このアプリは to_time を使っておらず、タイムゾーンも夏時間のない日本のため、Rails 8.1 の標準である :zone を使う。
    config.active_support.to_time_preserves_timezone = :zone
    
    config.paths.add 'lib', eager_load: true

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local
    # config.eager_load_paths << Rails.root.join("extras")

    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}'),to_s]
  end
end
