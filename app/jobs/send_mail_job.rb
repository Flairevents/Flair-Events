class SendMailJob < ApplicationJob
  queue_as :default

  def perform(*mails)
    mails.each do |mail|
      begin
        Mail::Message.from_yaml(mail).deliver
      rescue Exception => e
        AdminLogEntry.create(type: 'sending_email_failed', data: {message: mail, exception: "#{e.message}: #{e.backtrace}"})
      end
    end
  end
end
