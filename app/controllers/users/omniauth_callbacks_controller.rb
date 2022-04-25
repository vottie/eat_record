# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # skip_before_action :verify_authenticity_token, only: :create
  # You should configure your model like this:
  # devise :omniauthable, omniauth_providers: [:twitter]

  # You should also create an action method in this controller like this:
  # def twitter
  # end

  def google_oauth2
    logger.debug("google_oauth2 ----")
    callback_for(:google)
  end
  # More info at:
  # https://github.com/heartcombo/devise#omniauth

  # GET|POST /resource/auth/twitter
  def passthru
    super
    logger.debug("---- PASSTHRU ----")
  end

  def callback_for(provider)
    provider = provider.to_s
    logger.debug("OmniauthCallbacksController.provider #{provider}")
    @user = User.from_omniauth(request.env["omniauth.auth"])
    logger.debug("OmniauthCallbacksController.callback_for #{@user}")
    #@user = User.find_or_create_for_oauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "#{provider}".capitalize) if is_navigational_format?
    else
      session["devise.#{provider}_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url
    end
  end

  # GET|POST /users/auth/twitter/callback
  def failure
    # super
    redirect_to root_path
  end

  # protected

  # The path used when OmniAuth fails
  # def after_omniauth_failure_path_for(scope)
  #   super(scope)
  # end
end
