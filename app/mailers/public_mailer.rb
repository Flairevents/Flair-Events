class PublicMailer < ApplicationMailer
  def contact_submission(name, email, contact, subject, message)
    @name,@email,@contact,@subject,@message = name,email,contact,subject,message

    case @subject.to_i
    when 1
      mail(to: ['nicola@flairpeople.com', 'accounts@flairpeople.com'], from: email, subject: "Hiring from website")
    when 2
      mail(to: 'work@flairpeople.com', from: email, subject: "General question WS")
    when 3
      mail(to: 'work@flairpeople.com', from: email, subject: "Payroll from WS")
    when 4
      mail(to: 'accounts@flairpeople.com', from: email, subject: "Accounts from WS")
    when 5
      mail(to: 'work@flairpeople.com', from: email, subject: "Ledgend form WS")
    end
  end

  def quote_request_email(qoutes_request, email)
    @qoute = qoutes_request

    mail(to: email, from: qoutes_request.email, subject: 'Quote request website')
  end

  def quote_request_email_to_client(qoutes_request)
    @qoute = qoutes_request

    mail(to: qoutes_request.email, subject: 'Hello from Flair People we have your enquiry.')
  end

  def new_registration(user, account)
    @name = user.first_name
    @token = account.one_time_token
    @unsub = account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: "Welcome to Flair, let's get started.")
  end

  def remind_to_confirm_email(user, account)
    @name = user.first_name
    @token = account.one_time_token
    @unsub = account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: "#{@name}, Activate Your Profile and Start Working")
  end

  def remind_to_confirm_email_5(user, account)
    @name = user.first_name
    @token = account.one_time_token
    @unsub = account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: "#{@name}, Activate Your Profile and Start Working")
  end

  def remind_to_confirm_email_10(user, account)
    @name = user.first_name
    @token = account.one_time_token
    @unsub = account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: "#{@name}, Last Chance To Activate Your Profile")
  end

  def remind_to_confirm_email_30(user, account)
    @name = user.first_name
    @token = account.one_time_token
    @unsub = account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: "5 Days until we will remove your details.")
  end

  def forgot_password(user)
    @name = user.first_name
    @token = user.account.one_time_token
    @unsub = user.account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: 'Link to set your Flair Events password')
  end
end
