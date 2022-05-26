class ApplicationMailer < ActionMailer::Base
  default from: 'Flair Events <communications@eventstaffing.co.uk>'
  layout 'mailer'

  def unsub_header(token)
    headers['List-Unsubscribe'] = "<mailto:unsubscribe-#{token}@unsubscribe.eventstaffing.co.uk>"
  end
end
