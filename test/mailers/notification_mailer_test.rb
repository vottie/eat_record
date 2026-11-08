require "test_helper"

class NotificationMailerTest < ActionMailer::TestCase
  test "welcome_email is addressed to the user from the configured sender" do
    mail = NotificationMailer.welcome_email("newbie@example.com")

    assert_equal ["newbie@example.com"], mail.to
    assert_equal ["noreply@example.com"], mail.from
    assert_equal "title-xxxx", mail.subject
  end

  test "welcome_email has text and html parts that greet the user" do
    mail = NotificationMailer.welcome_email("newbie@example.com")

    assert_equal %w[text/html text/plain], mail.parts.map(&:mime_type).sort
    mail.parts.each { |part| assert_includes part.body.to_s, "newbie@example.com 様" }
  end

  test "welcome_email is delivered" do
    assert_emails 1 do
      NotificationMailer.welcome_email("newbie@example.com").deliver_now
    end
  end
end
