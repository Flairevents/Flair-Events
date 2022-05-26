class OverrideMailRecipient
  def self.delivering_email(mail)
    Rails.logger.info("Overriding email to: #{mail.to} with ")
    mail.to = ['flp.rsc.test@gmail.com']
  end
end

Rails.application.configure do
  unless Rails.env.production?
    config.action_mailer.interceptors = %w[OverrideMailRecipient]
  end
end