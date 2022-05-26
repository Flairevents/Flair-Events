class V2::QuoteRequestsController < ApplicationController
	def create
		params[:start_date] = hash_to_date(params[:start_date])
		params[:finish_date] = hash_to_date(params[:finish_date])
		quote_params = params.except(:redirect)
		@quote_params = quote_params.except(:utf8, :commit, :authenticity_token)
  	@quote_request = QuoteRequest.new(quote_request_params)

		if @quote_request.save
			send_mail(PublicMailer.quote_request_email(@quote_request, 'clare@flairpeople.com'))
			send_mail(PublicMailer.quote_request_email(@quote_request, 'accounts@flairpeople.com'))
			send_mail(PublicMailer.quote_request_email_to_client(@quote_request))

			flash[:job_board_title] = "Successfully Submitted"
			flash[:job_board] = 'Thank you! Your request has been delivered. Flair office staff will get back to you as quickly as possible.'
			flash[:job_board_1] = 'If urgent, you can always call us at 0161 241 2441.'
			flash[:button_title] = "Got it"
			flash[:redirect] = params[:redirect]
			return redirect_to "/hire"
		else
			flash[:notice] = "Request not submitted try again"
			return redirect_to "/hire"
		end
	end

	private

	def quote_request_params
		@quote_params.permit(:name, :company_name, :telephone, :email, :location, :post_code, :start_date, :finish_date, :job_position, :other_facts, :job_category)
	end

	def hash_to_date(hash)
	  if hash[:year].present? && hash[:month].present? && hash[:day].present?
		year = hash[:year].to_i
		month = hash[:month].to_i
		day = [hash[:day].to_i, Time.days_in_month(month, year)].min
		Date.civil(year, month, day)
	  end
	end

end
