require 'open-uri'
require 'uri'
require "rexml/document"

# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  def new
    super
    logger.debug("RegistrationsController.new()")
  end

  # POST /resource
  def create
    super
    logger.debug("RegistrationsController.create()")
    NotificationMailer.welcome_email(params[:user][:email]).deliver
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
    logger.debug(current_user.inspect)
    #logger.debug("#{params[:user][:zip]}")
    if params[:user][:zip] != nil
      logger.debug("update() #{params[:zip]}")
      url = 'https://geoapi.heartrails.com/api/json?method=searchByPostal&postal='
      res = OpenURI.open_uri(url+params[:user][:zip])
      hash = JSON.load(res.read)
      logger.debug(hash["response"]["location"][0])
      params[:user][:latitude] = hash["response"]["location"][0]["y"].to_f
      params[:user][:longitude] = hash["response"]["location"][0]["x"].to_f
    end
    current_user.update(user_record_params)
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
    def user_record_params
      params.require(:user).permit(:email, :encrypted_password, :reset_password_token, :reset_password_sent_at, :remember_created_at, :created_at, :update_at, :provider, :uid, :username, :zip, :latitude, :longitude)
    end
end
