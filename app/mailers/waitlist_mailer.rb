class WaitlistMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.waitlist_mailer.availability_notification.subject
  #
  def availability_notification
    @greeting = "Hi"

    mail to: "to@example.org"
  end
end
