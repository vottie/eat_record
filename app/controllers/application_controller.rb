class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  SIGNUP_CLOSED_NOTICE = "現在、新規登録は受け付けていません。".freeze

  helper_method :signup_open?

  protected

  # 新規登録(パスワードでの登録と、Google ログインでのユーザーの自動作成)は、既定で閉じている。
  # 開けるのは、環境変数 ALLOW_SIGNUP が、ちょうど "1" のときだけ(サーバーの .env に書いて、Puma を再起動する)。
  def signup_open?
    ENV["ALLOW_SIGNUP"] == "1"
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username])
  end

  def after_sign_in_path_for(resources)
    eat_records_path
  end

  def after_sign_out_path_for(resources)
    new_user_session_path
  end
end
