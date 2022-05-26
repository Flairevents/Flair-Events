require 'shared_event_methods'
# Serves up all the pages in the "Public Zone" -- the part of the site which does not require login

class V2::PublicController < ApplicationController
  layout 'v2/layouts/public'

  before_action :load_funky_popup_text

  include ActionView::Helpers::SanitizeHelper

  def home
    @prospect = current_user
    @welcome = TextBlock['welcome-message']
    @years = full_years_between(Date.today, Date.new(2000, 6, 1))
    event_category = {}
    @events = {}
    EventCategory.all.each do |category|
      @events[category.name] = []
      event_category[category.id] = category.name
    end
    Event.where(show_in_history: true, status: 'CLOSED').order('date_end DESC').pluck_to_hashes(:category_id, :date_end, :history_tr).each do |event|
      @events[event_category[event[:category_id]]] << event
    end
    @number_of_contracts = TextBlock['total-events']
    @active_team = Prospect.where(status: 'EMPLOYEE', last_login: 6.months.ago..Time.current).includes(:gig_requests).where(gig_requests: {created_at:  6.months.ago..Time.current}).count
    @contracts = Event.where(created_at: Date.today.at_beginning_of_year.last_year...Date.today.at_beginning_of_year).size
    @browser = Browser.new(request.env["HTTP_USER_AGENT"])
    if request.variant.present?
      return render 'v2/mobile/shared/home'
    else
      return render 'v2/shared/home'
    end
  end

  def workers
    @featured_events = Event.includes(:jobs, :region).visible.not_finished.where(show_in_public: true, show_in_featured: true, jobs: { include_in_description: true }).references(:jobs, :region).order(:public_date_start)

    # featured_events = {}
    # @featured_events = events.partition { |event| event.show_in_featured }
    Rails.logger.info "HEllo"
    Rails.logger.info "#{@featured_events}"
    Rails.logger.info "#{@featured_events.length}"

    if request.variant.present?
      return render 'v2/mobile/shared/workers'
    else
      return render 'v2/shared/workers'
    end
  end

  def add_category_events
    # should be order the way that the categories should be ordered
    categories = ["Events", "Sports", "Promotional", "Hospitality", "Logistics", "Concert", "Commercial"]

    EventCategory.find(1).update(name: "Events")
    EventCategory.find(2).update(name: "Sports")
    EventCategory.find(3).update(name: "Promotional")
    EventCategory.find(4).update(name: "Hospitality")
    EventCategory.find(5).update(name: "Logistics")
    EventCategory.find(6).update(name: "Concert")
    if EventCategory.all.count > 6
      EventCategory.find(7).update(name: "Commercial")
    else
      EventCategory.create(name: "Commercial")
    end

    EventCategory.where.not(id: [1,2,3,4,5,6,7]).each do |ec|
      ec.destroy
    end

    render json: :success
  end

  def full_years_between(date1,date2)
    month = (date1.year * 12 + date1.month) - (date2.year * 12 + date2.month)
    (month/12.0).floor
  end

  def about
    # This was from the original site that had a rudimentray CMS. Not currently used.
    # @about_us = TextBlock['about-us']
    if request.variant.present?
      return render 'v2/mobile/shared/about'
    else
      return render 'v2/shared/about'
    end
  end

  def contact
    @errors = Hash.new { |h,k| h[k] = [] }

    if request.post?
      [:name, :email, :contact, :subject, :message].each { |k| params[k].strip! if params[k] }
      @errors[:email]   << "E-mail address is invalid" if params[:email] !~ /\A[^@]+@[^@]+\.[^@]+\z/
      @errors[:email]   << "E-mail address can't be more than 500 characters" if params[:email]&.size > 500
      @errors[:name]    << "Name can't be blank" if params[:name].blank?
      @errors[:name]    << "Name can't be more than 300 characters" if params[:name]&.size > 300
      @errors[:subject] << "Subject can't be blank" if  params[:subject].blank?
      @errors[:subject] << "Subject can't be more than 300 characters" if params[:subject]&.size > 300
      @errors[:message] << "Message can't be blank" if params[:message].blank?
      @errors[:message] << "Message can't be more than 5000 characters" if params[:message]&.size > 5000

      if @errors.empty?
        send_mail(PublicMailer.contact_submission(params[:name], params[:email], params[:contact], params[:subject], params[:message]))
        # flash[:alert] = "Thank you! Your message has been delivered. Flair office staff will get back to you as quickly as possible. If urgent, you can always call us at #{strip_tags(TextBlock['company-tel'])}."
        @name = params[:name]
        if request.variant.present?
          return render 'v2/mobile/shared/contact_holding'
        else
          return render 'v2/shared/contact_holding'
        end
      else
        @name, @email, @contact, @subject, @message = params[:name], params[:email], params[:contact], params[:subject], params[:message]
      end
    elsif current_user
      @name  = "#{current_user.first_name} #{current_user.last_name}"
      @email = current_user.email
    end

    @address = TextBlock['company-address']
    @tel     = TextBlock['company-tel']
    @mobile  = TextBlock['company-mobile']

    if request.variant.present?
      render 'v2/mobile/shared/contact'
    else
      render 'v2/shared/contact'
    end
  end

  def contact_holding
    render 'v2/shared/contact_holding'
  end

  def events
    @regions = Region.all.sort_by(&:name).pluck(:name)
    @category = 'All' # Temp: Always show events in all categories

    @category = (params[:category] == 'All' || !params[:category].present?) ? nil : params[:category]
    @region =   (params[:region] == 'All'   || !params[:region].present?)   ? nil : params[:region].tr('_', ' ')
    @keyword = params[:keyword].present? ? params[:keyword].to_s : nil

    @show_event = params[:view_event]

    query = ''
    if @category
      category_names =   @category == 'Events' ? 'Events,Concert' : @category
      category_ids = EventCategory.where(name: category_names.split(',').map(&:titleize)).ids
      query << "category_id IN (#{category_ids.join(',')})"
    end

    #jobs and event query search
    if @keyword
      if query.present?
        query << " AND "
      end
      query << "(lower(events.display_name) LIKE '%#{@keyword.downcase}%' OR lower(events.jobs_description) LIKE '%#{@keyword.downcase}%' OR lower(jobs.name) LIKE '%#{@keyword.downcase}%' OR lower(jobs.public_name) LIKE '%#{@keyword.downcase}%')"
    end

    if @region
      region2 = @region.delete(' ')
      if query.present?
        query << " AND "
      end
      if @region != region2
        query << "(lower(location) LIKE '%#{@region.downcase}%' OR lower(regions.name) LIKE '%#{@region.downcase}%') OR (lower(location) LIKE '%#{region2.downcase}%' OR lower(regions.name) LIKE '%#{region2.downcase}%')"
      else
        query << "(lower(location) LIKE '%#{@region.downcase}%' OR lower(regions.name) LIKE '%#{@region.downcase}%')"
      end
    end



    events = Event.includes(:jobs, :region).visible.not_finished.where(show_in_public: true, jobs: { include_in_description: true }).where(query).references(:jobs, :region).order(:public_date_start)

    # if @region
    #   events = Event.joins(:jobs, :region).visible.not_finished.where(region_id: Region.find_by_name(@region).id, show_in_ongoing: @ongoing, show_in_public: true).where(query)
    # else
    #  events = Event.joins(:jobs, :region).visible.not_finished.where(show_in_ongoing: @ongoing, show_in_public: true).where(query)
    # end

    @status = {}
    @status.default = 'none'

    if events.empty?
      @empty_message = "No"
      @empty_message << " "+@category if @category.present?
      @empty_message << ' Ongoing' if @ongoing.present?
      @empty_message << " events"
      # @empty_message << " in #{Region.find_by_name(@region).name}" if @region.present?
      @empty_message << "."
    end

    featured_events = {}
    @job_groups = SharedEventMethods::get_job_groups(events)
    @featured_events, @events = events.partition { |event| event.show_in_featured }
    @events = @featured_events + @events

    @featured_events.each do |fe|
      featured_events[fe.id] = true
    end

    @featured_events = featured_events

    @events = @events.map{|event| event.jobs.where(include_in_description: true).count > 0 ? event : []}.flatten
    @events = Kaminari.paginate_array(@events).page(params[:page]&.last).per(10)

    if request.xhr?
      render json: {contents: render_to_string(partial: 'v2/shared/events', locals: {events: @events, featured_events: @featured_events})}
    else
      if request.variant.present?
        return render '/v2/mobile/shared/events'
      else
        return render 'v2/shared/events'
      end
    end
  end

  def join_us
    @entries = FaqEntry.order('position ASC')
    @entries_joining_flair = @entries.where(topic: 'joining_flair', position: 2).order(:id)
    @entries_shift_questions =    @entries.where(topic: 'shift_questions', position: 2).order(:id)
    @entries_wages =    @entries.where(topic: 'wages', position: 2).order(:id)
    render 'v2/shared/join_us'
  end

  def privacy
    @title   = 'Privacy and Cookie Notice'
    @message = TextBlock['privacy']
    @updated_date = TextBlock['privacy_date']
    render 'v2/shared/boilerplate'
  end

  def registration
    @title   = 'Registration'
    render 'register'
  end

  def login
    # If the user was redirected here, which page were they *trying* to access?
    # If redirected, this may come through in the flash.
    # If this is a form submission, it will come in the params.

    @target = flash[:target] || params[:target] || "#{Flair::Application.config.base_https_url}/staff"

    # Number of jobs
    public_events_jobs = Event.where(status: ["OPEN", "HAPPENING"]).map{|event| event.jobs.all }.flatten
    @no_of_jobs = public_events_jobs.map{|job| job.number_of_positions }.compact.sum

    if token = params[:token]
      if login_by_token(token)
        current_user.account.confirmed_email = true
        current_user.account.save!
        current_user.previous_login = current_user.last_login
        current_user.last_login = Date.today
        current_user.save!
        if current_user.account.password_hash
          flash[:notice] = "Welcome, you're logged in now!"
          return redirect_to @target
        else
          # Manually created accounts will not yet have a password, so have them set a password
          flash[:notice] = "Welcome, you're logged in now! Please set your password."
          return redirect_to "#{Flair::Application.config.base_https_url}/staff/set_password"
        end
      else
        flash.now[:error] = "Sorry, something was wrong with your login link! Perhaps you used it already? (It's only good for one time.)"
      end
    elsif request.post? # form submission
      params[:login_email] = (params[:login_email] || '').gsub(/\s+/, '').downcase
      email, password = params[:login_email], params[:login_password]
      if email.blank? || password.blank?
        flash.now[:error] = "Sorry, you need to enter both e-mail address and password."
        return back_to_login
      else
        result = login_as_prospect(email, password)
        if result == :success
          if current_user
            current_user.previous_login = current_user.last_login
            current_user.last_login = Date.today
            current_user.save
          end
          
          root_page = if current_user.lacking_needed_share_code?
            "/staff#application-identification"
          else
            @target
          end
          return redirect_to root_page
        elsif result == :not_initialized
          flash[:error] = "You need to create an account before accessing the site. Please fill out the registration form to create an account."
        elsif result == :not_confirmed
          flash[:error] = "You need to confirm your e-mail address by clicking on the login link we sent you first. We're sending it to you again right now. Please check your e-mail inbox."
          user = Prospect.find_by_email(params[:login_email])
          user.account.generate_one_time_token!
          send_mail(PublicMailer.new_registration(user, user.account))
          user.account.update(confirmed_email: true)
          result = login_as_prospect(user.email, password)
          if current_user
            current_user.previous_login = current_user.last_login
            current_user.last_login = Date.today
            current_user.save
          end
          user.account.update(confirmed_email: false)
          return redirect_to '/onboard'
        elsif result == :no_such_account
          flash.now[:error] = "We don't have anyone with that e-mail address on file. If you haven't registered yet, please fill in the registration form. Otherwise, please try again."
        elsif result == :wrong_password
          flash.now[:title] = "Sorry!"
          flash.now[:error] = "The password you entered was not correct. Please try again."
          return back_to_login
        elsif result == :locked_out
          flash.now[:title] = "Sorry!"
          flash.now[:error] = "Your account is locked as a safety measure (probably because you entered the wrong password too many times). Please contact us at 0161 241 2441 or work@flairevents.co.uk and we'll help you sort this out."
        elsif result == :forbidden
          flash.now[:error] = "Thank you for trying to log-in, however you are no longer a part of the Flair Events Team.  If you would like to discuss this further, please give us a call in the office on 0161 241 2441"
        else
          raise "Invalid! #{result}"

          if request.variant.present?
            return render '/v2/mobile/public/login'
          end
        end
      end
    end

    if current_user
      if !current_user.is_a?(Officer)
        return redirect_to '/staff'
      end
    end

    if request.variant.present?
      return render '/v2/mobile/public/login'

    end
  end

  def register
    # Make things easier, pre-fill for dev purposes
    # if request.get? and (Rails.env.development? or Rails.env.staging?)
    #   @first_name       = 'First name'
    #   @last_name        = 'Last name'
    #   @email            = 'example@example.com'
    #   @email_confirm    = 'example@example.com'
    #   @password         = '12345678'
    #   @password_confirm = '12345678'
    #   @agree_to_mail    = true
    #   @agree_to_policy  = true
    #   @mobile           = '01234567890'
    #   @date_of_birth    = Date.civil(1980,1,20)
    #   @post_code        = 'PO16 7GZ'
    #   @city             = 'Nowhere'
    # end

    # User submits registration form
    if request.post?
      if (user = Prospect.find_by_email(params[:email])) && user.account
        if user.account.confirmed_email
          flash.now[:error] = "You have already registered! Please enter your password to log in."
          @login_email = params[:email]
        else
          flash.now[:error] = "You have already registered! Please click the login link we sent to your e-mail inbox (and check your spam folder if you don't find it). We're sending it again right now."
          user.account.generate_one_time_token!
          send_mail(PublicMailer.new_registration(user, user.account))
        end
      elsif params[:password] != params[:password_confirm]
        flash.now[:error] = "The passwords you entered don't match. Please try again."
        back_to_register
        @password = @password_confirm = nil
      elsif reason = Account.why_invalid?(params[:password])
        flash.now[:error] = reason
        back_to_register
        @password = @password_confirm = nil
      # elsif !params[:agree_to_policy]
      #   flash.now[:error] = "To apply for work with Flair Event Staffing, you must read and agree to our privacy policy. You can view our privacy policy at: http://eventstaffing.co.uk/privacy"
      #   back_to_register
      else
        params[:mobile].gsub!(/\D/,'') if params[:mobile]
        if params[:mobile].blank? || params[:mobile].length < 7
          flash.now[:error] = "Please enter a valid contact number."
          back_to_register
          if request.variant.present?
            return render '/v2/mobile/public/register'
          end
          return
        else
          if user = Prospect.where(email: params[:email]).first
            # This Prospect was manually created and doesn't have an Account yet
            user.first_name = params[:first_name]
            user.last_name  = params[:last_name]
            user.post_code  = params[:post_code]
            user.mobile_no  = params[:mobile]
          else
            user = Prospect.new(first_name: params[:first_name], last_name: params[:last_name], email: params[:email], post_code: params[:post_code], mobile_no: params[:mobile], applicant_status: 'UNCONFIRMED', city: params[:city])
          end

          if user.valid?
            user.new_employee = true
            user.save!
            account = Account.new(user: user)
            account.password = params[:password]
            if bypass_registration(user)
              account.confirmed_email = true
              account.save!
              flash[:notice] = "Registered! You may now log in to the staff zone. If you have any issues logging in, please contact Flair Events directly."
            else
              account.generate_one_time_token!
              send_mail(PublicMailer.new_registration(user, account))
              session[:registration_email] = user.email
              # flash[:notice] = "You may now confirm your account in your email."
              # redirect_to '/registration_confirmation'
              account.confirmed_email = true
              account.save!
              result = login_as_prospect(user.email, params[:password])
              current_user.previous_login = current_user.last_login
              current_user.last_login = Date.today
              current_user.save!
              account.confirmed_email = false
              account.save!
              redirect_to '/onboard'
              return
            end
            result = login_as_prospect(user.email, params[:password])
            current_user.previous_login = current_user.last_login
            current_user.last_login = Date.today
            current_user.save!
            redirect_to '/onboard'
            return
          else
            @first_name = params[:first_name]
            @last_name = params[:last_name]
            @email = params[:email]
            @password = params[:password]
            @password_confirm = params[:password_confirm]
            @mobile = params[:mobile]
            @city = params[:city]
            @post_code = params[:post_code]
            flash.now[:error] = user.errors.full_messages.to_sentence
            back_to_register
            if request.variant.present?
              return render '/v2/mobile/public/register'
            end
            return
          end
        end
      end
    end

    if request.variant.present?
      return render '/v2/mobile/public/register'
    end
  end

  def onboard
    if current_user
      @prospect = current_user
      if @prospect.account.confirmed_email == false
        if request.variant.present?
          render 'v2/mobile/shared/onboard'
        else
          render 'v2/shared/onboard'
        end
      else
        redirect_to '/staff'
      end
    else
      redirect_to '/login'
    end
  end

  def registration_confirmation
    if defined?(session[:registration_email])
      @message = "Registered! Your login link has been sent to #{session[:registration_email]}. Please check your spam folder if you don't find it. Log in to fill in your application form and select events of interest."
      session.delete(:registration_email)
    else
      redirect_to '/'
    end
  end

  def resend_confirmation
    user = current_user
    account = user.account
    send_mail(PublicMailer.new_registration(user, account))
    session[:registration_email] = user.email
    flash[:notice] = "Resent - remember to check your junk box in case your link is hiding in here. Refresh your emails, wait a few minutes or call our office."
    flash[:second_line] = "We are here to help: 0161 241 2441"
    redirect_to '/onboard'
  end

  def forgot_password
    if request.post? && params[:email].present? # form submission
      params[:email] = (params[:email] || '').gsub(/\s+/, '').downcase
      user = Prospect.where(email: params[:email]).first
      if user
        if user.has_been?
          flash[:error] = "Thank you for trying to log-in, however you are no longer a part of the Flair Events Team.  If you would like to discuss this further, please give us a call in the office on 0161 241 2441."
          flash.keep
          redirect_to '/home'
        else
          user.account ||= Account.new(user: user)
          user.account.generate_one_time_token!
          send_mail(PublicMailer.forgot_password(user))
          flash[:notice] = "Please check your e-mail. We've sent you a one-time login link which you can use to set your password again."
          flash.keep # this is required when redirecting from POST request!
          redirect_to '/login'
        end
      else
        flash.now[:error] = "Sorry, we don't have anyone with that e-mail address on file. Are you sure you entered it correctly?"
        render "/v2/public/login"
      end
    end
  end

  # If a user clicks "Forgot Password", we send them a link to this action (with a one-time login token)
  # after which we log them in, set account.one_time_token to nil, and redirect to the Staff Zone action 'set_password'
  def set_password
    token = params.dig(:token)
    if token.present? && login_by_token(token)
      flash[:notice] = "Welcome, you're logged in now! Please set your password."
      redirect_to "#{Flair::Application.config.base_https_url}/staff/set_password"
    else
      flash[:error] = "Sorry, something was wrong with your login link! Perhaps you used it already? (It's only good for one time.)"
      redirect_to '/login'
    end
  end

  def industry
    if params[:industry].present?
      if request.variant.present?
        render "v2/mobile/industry/#{params[:industry]}"
      else
        render "v2/industry/#{params[:industry]}"
      end
    else
      redirect_to root_path
    end
  end

  def case_studies
    if params[:industry].present?
      if request.variant.present?
        render "v2/mobile/case_studies/#{params[:industry]}"
      else
        render "v2/case_studies/#{params[:industry]}"
      end
    else
      if request.variant.present?
        render 'v2/mobile/case_studies/index'
      else
        render 'v2/case_studies/index'
      end
    end
  end

  private

  # these methods are used when we want to send the user back to the login/register page with fields already filled in
  # when we want to send them back with the fields blank, we can either redirect, or just render directly
  # TODO: Replace params method with a model
  def back_to_login
    @login_email = params[:login_email]
    if request.variant.present?
      return render '/v2/mobile/public/login'
    end
  end

  def back_to_register
    @email  = params[:email]
    params[:email] = (params[:email] || '').gsub(/\s+/, '').downcase
    params[:email] = (params[:email_confirm] || '').gsub(/\s+/, '').downcase
    @first_name, @last_name = params[:first_name], params[:last_name]
    @password, @password_confirm = params[:password], params[:password_confirm]
    @agree_to_policy = params[:agree_to_policy]
    @mobile = params[:mobile]
    @post_code = params[:post_code]
    @city = params[:city]
  end

  def hash_to_date(hash)
    Date.civil(hash[:year].to_i, hash[:month].to_i, hash[:day].to_i)
  rescue
    nil # nonexistent date, like April 31st
  end

  def date_hash_blank?(hash)
    hash[:year].blank? || hash[:month].blank? || hash[:day].blank?
  end

  ##### Bypass registration if a certain mail provider starts blocking our emails
  ##### We allow bypassing registration for these users. We'll also display slightly different messages
  def bypass_registration(user)
    # Rails.env.staging? || Rails.env.development? || (/@gmail/.match(user.email) != nil)
    Rails.env.staging? || Rails.env.development?
  end

  def style_guide
    @title   = 'Style Guide'
    render 'style_guide'
  end
end
