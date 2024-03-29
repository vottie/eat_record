class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username])
    devise_parameter_sanitizer.permit(:edit, keys: [:username])
  end

  def after_sign_in_path_for(resources)
    eat_records_path
  end

  def after_sign_out_path_for(resources)
    new_user_session_path
  end
end
