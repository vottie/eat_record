# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super
    logger.debug("Users::SessionsController new")
  end

  # POST /resource/sign_in
  def create
    super
    logger.debug("Users::SessionsController create")
  end

  # DELETE /resource/sign_out
  def destroy
    super
    logger.debug("Users::SessionsController destroy")
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    logger.debug("Users::SessionsController configure_sign_in_params")
  end
end
