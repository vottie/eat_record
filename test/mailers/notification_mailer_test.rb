require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "welcome_email is addressed to the user from the configured sender" do
    mail = NotificationMailer.welcome_email("newbie@example.com")

    assert_equal ["newbie@example.com"], mail.to
    assert_equal ["noreply@example.com"], mail.from
    assert_equal "title-xxxx", mail.subject
  end

  # welcome_email.txt.erb は、Rails が認識する拡張子(.text.erb)ではないため使われず、HTML だけのメールになる(既知の不具合。ここでは対象にしない)。
  test "welcome_email greets the user in the body" do
    mail = NotificationMailer.welcome_email("newbie@example.com")

    assert_equal "text/html", mail.mime_type
    assert_includes mail.body.to_s, "newbie@example.com 様"
  end

  test "welcome_email is delivered" do
    assert_emails 1 do
      NotificationMailer.welcome_email("newbie@example.com").deliver_now
    end
  end
end
