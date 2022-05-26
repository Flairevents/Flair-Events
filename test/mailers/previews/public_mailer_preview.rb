# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class PublicMailerPreview < ActionMailer::Preview
  def new_registration
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")
    account = Account.find_by(user: prospect)

    PublicMailer.new_registration(prospect, account)
  end

  def remind_to_confirm_email_5
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")
    account = Account.find_by(user: prospect)

    PublicMailer.remind_to_confirm_email_5(prospect, account)
  end

  def remind_to_confirm_email_10
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")
    account = Account.find_by(user: prospect)

    PublicMailer.remind_to_confirm_email_10(prospect, account)
  end

  def remind_to_confirm_email_30
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")
    account = Account.find_by(user: prospect)

    PublicMailer.remind_to_confirm_email_30(prospect, account)
  end

  def quote_request_email
    quote = QuoteRequest.last

    PublicMailer.quote_request_email(quote)
  end

  def quote_request_email_to_client
    quote = QuoteRequest.last

    PublicMailer.quote_request_email_to_client(quote)
  end
end
