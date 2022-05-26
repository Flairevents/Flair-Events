class ExceptionMailer < ApplicationMailer

  def notify(id, info)
    @id = id
    @info = info
    mail(from: 'exception.notifier@eventstaffing.co.uk', to: 'error@appybara.com', subject: "Error: #{id}")
  end
  
end
