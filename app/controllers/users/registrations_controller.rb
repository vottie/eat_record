class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    NotificationMailer.welcome_email(params[:user][:email]).deliver
  end
end
