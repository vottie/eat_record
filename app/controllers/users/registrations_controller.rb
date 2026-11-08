# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # 新規登録が閉じている間は、登録の画面と送信を受け付けない(既存ユーザーのアカウント編集・削除は、これまでどおり)
  before_action :require_signup_open, only: %i[new create]
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
    logger.debug("RegistrationsController.new()")
  end

  # POST /resource
  def create
    # 登録に成功したときだけ、登録されたアドレスへウェルカムメールを送る
    super do |resource|
      NotificationMailer.welcome_email(resource.email).deliver_now if resource.persisted?
    end
    logger.debug("RegistrationsController.create()")
  end

  # GET /resource/edit
  def edit
    super
    logger.debug("RegistrationsController.edit()")
  end

  # PUT /resource
  def update
    logger.debug("RegistrationsController.update()")
    super
  end

  # DELETE /resource
  def destroy
    super
    logger.debug("RegistrationsController.destroy()")
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def require_signup_open
    redirect_to new_user_session_path, notice: SIGNUP_CLOSED_NOTICE unless signup_open?
  end
end
