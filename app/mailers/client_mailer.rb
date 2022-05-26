class ClientMailer < ApplicationMailer
  def activate_account(user, account)
    @name = user.first_name
    @token = account.one_time_token
    mail(to: user.email, subject: 'Flair Events Client Account Activation')
  end

  # def quote_request_email(qoutes_request)
  #   @name = "#{qoutes_request.first_name} #{qoutes_request.last_name}"
  #   @company_name = qoutes_request.company_name
  #   @telephone = "\t\t#{qoutes_request.telephone}"
  #   @email = qoutes_request.email
  #   # @contract_name = "\t\t#{qoutes_request.contract_name}"
  #   @location = qoutes_request.location
  #   # @post_code = qoutes_request.post_code
  #   @start_date = qoutes_request.start_date.strftime('%d-%m-%Y')
  #   @finish_date = qoutes_request.finish_date.strftime('%d-%m-%Y') if qoutes_request.finish_date != nil
  #   @job_position = qoutes_request.job_position
  #   @job_category = qoutes_request.job_category
  #   # @experience_level = qoutes_request.experience
  #   # @working_pattern = qoutes_request.working_pattern
  #   # @number_of_people = qoutes_request.number_of_people
  #   # @wage_rates = qoutes_request.wage_rates
  #   @other_facts = qoutes_request.other_facts
  #   # mail(to: 'clients@flairevents.co.uk', from: @email, subject: 'Quote Request Website')
  #   mail(to: ['nicola@flairpeople.com', 'accounts@flairpeople.com'], from: @email, subject: 'Hire Form')
  # end
  #
  # def quote_request_email_to_client(qoutes_request)
  #   @quoutes_request = quoutes_request
  #
  #   @name = "#{qoutes_request.first_name}"
  #   @full_name = "#{qoutes_request.first_name} #{qoutes_request.last_name}"
  #   @company_name = qoutes_request.company_name
  #   @telephone = "\t\t#{qoutes_request.telephone}"
  #   @email = qoutes_request.email
  #   # @contract_name = "\t\t#{qoutes_request.contract_name}"
  #   @location = qoutes_request.location
  #   # @post_code = qoutes_request.post_code
  #   @start_date = qoutes_request.start_date.strftime('%d-%m-%Y')
  #   @finish_date = qoutes_request.finish_date.strftime('%d-%m-%Y') if qoutes_request.finish_date != nil
  #   @job_position = qoutes_request.job_position
  #   @job_category = qoutes_request.job_category
  #   # @experience_level = qoutes_request.experience
  #   # @working_pattern = qoutes_request.working_pattern
  #   # @number_of_people = qoutes_request.number_of_people
  #   # @wage_rates = qoutes_request.wage_rates
  #   @other_facts = qoutes_request.other_facts
  #   mail(to: @email, subject: 'Hello from Flair People we have your quote!')
  # end
end
