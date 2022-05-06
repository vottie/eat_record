class NotificationMailer < ApplicationMailer
  default from: ENV['WELCOME_MAILER_ADDRESS']

  def welcome_email(email)
    @email = email
    logger.debug("User : #{email}")
    mail(to: email, subject: 'title-xxxx')
  end
end
