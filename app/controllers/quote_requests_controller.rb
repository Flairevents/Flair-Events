class QuoteRequestsController < ApplicationController

	def create
    @quote_request = QuoteRequest.new(quote_request_params)
		if @quote_request.save
			send_mail(PublicMailer.quote_request_email(@quote_request))
			send_mail(PublicMailer.quote_request_email_to_client(@quote_request))
			flash[:notice] = 'Thank you! Your request has been delivered. Flair office staff will get back to you as quickly as possible. If urgent, you can always call us at 0161 241 2441.'
			redirect_to root_path
		else
			flash[:alert] = "Request not submitted try again"
			redirect_to root_path
		end
	end

	private

	def quote_request_params
		params.require(:quote_request).permit(:first_name, :last_name, :company_name, :telephone, :email, :contract_name, :location, :post_code, :start_date, :finish_date, :job_position, :full_range, :number_of_people, :wage_rates, :other_facts, :job_category, :experience, :working_pattern)
	end

end
