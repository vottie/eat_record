class NotificationMailer < ApplicationMailer
  default from: 'xxxxx@xxxx.xxx'

  def welcome_email(email)
    @email = email
    logger.debug("User : #{email}")
    mail(to: email, subject: 'title-xxxx')
  end
end
