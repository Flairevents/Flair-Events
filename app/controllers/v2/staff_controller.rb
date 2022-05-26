require 'file_uploads'
require 'shared_event_methods'
require 'user_info'

class V2::StaffController < ApplicationController
  include FileUploads
  layout 'v2/layouts/staff'

  # force_ssl is configured in config/evironments/*.rb
  # For staging however, this is too strict and browsers will prevent access to the staging site if the certificate is
  #   invalid, so we set it here instead
  force_ssl if Rails.env.staging?

  only_accessible_to_prospects except: [:check_if_logged_in, :relogin, :unsubscribe], timeout: 2.hours

  before_action :load_funky_popup_text
  before_action :authenticate_user!, except: [:relogin, :refresh_online_interview_tab, :get_hired_status, :refresh_events, :unsubscribe]
  before_action :authenticate_user_polling!, only: [:refresh_online_interview_tab, :get_hired_status, :refresh_events]
  before_action :check_if_confirmed, except: [:logout]
  before_action :check_if_user_done_profile, only: [:events]

  ##### In case rails reuses one of the office zone threads, make sure to clear the current user.
  before_action :set_user
  def set_user
    UserInfo.current_user = current_user
    UserInfo.controller_name = controller_name
  end

  def seen_rejected_event
    if request.post?
      if params[:type] == "APPLICANT"
        rejected_event = RejectEvent.find(params[:rejected_event_id])
        rejected_event.has_seen = true
        rejected_event.save
        return render json: {status: :success}
      else
        rejected_event = RejectEvent.find(params[:rejected_event_id])
        rejected_event.has_seen_2 = true
        rejected_event.save
        return render json: {status: :success}
      end
    end
    redirect_to "/staff"
  end

  def change_new_employee_status
    if request.post?
      prospect = current_user

      prospect.update(new_employee: true)

      return render json: "okay"
    end
    return redirect_to "/staff"
  end

  def index
    @prospect = current_user
    # check if user has emergency contact
    if request.referer.present? && request.referer.split('/').last == 'login'
      if @prospect.status != "APPLICANT"
        if @prospect.new_employee # NEW STAFF
          if !@prospect.has_personal_details?
            # flash[:notice] = "Please complete your profile to be eligible to work and to proceed to other sections."
            if request.referer.split('/').last != 'staff'
              flash[:landing_page] = "Two emergency contacts boxes to quickly fill in, and remember keep your employee admin up to date, when working with us."
              flash[:second_line] = "Welcome to a #different9to5"
              flash[:title] = "Yah, you are now Flair team."
              flash[:button] = "Set Profile"
              flash[:returning] = "false"
            end
          end
        else
          # RETURNING STAFF
          if !@prospect.has_personal_details?
            flash[:landing_page] = "Visit your profile and application form to polish work experience evidence, upload professional head shot or add interest and skills for job matching."
            flash[:second_line] = "New: key Information (KID) terms to view & agree"
            flash[:title] = "Welcome to your new Flair look."
            flash[:button] = "Set Profile"
            flash[:returning] = "true"
          end
        end
      end
    end
    #Events
    @confirmed_events = Event.includes(:jobs, :region).find(
        [
          Gig.joins(:event).where('gigs.prospect_id = ? AND events.date_end >= ? AND gigs.status = ?', @prospect.id, Date.today, 'Active').pluck('gigs.event_id'),
          GigRequest.joins(:event).where(spare: true).where('gig_requests.prospect_id = ? AND gig_requests.gig_id IS NULL AND events.date_end >= ?', @prospect.id, Date.today).pluck(:event_id)
        ].flatten.uniq
      ).sort_by(&:public_date_start)
    @pending_events   = Event.includes(:jobs, :region).find(GigRequest.joins(:event).where(spare: false).where('gig_requests.prospect_id = ? AND gig_requests.gig_id IS NULL AND events.date_end >= ?', @prospect.id, Date.today).pluck(:event_id)).sort_by(&:public_date_start)
    @deselect_redirect = '/staff#contracts'
    # @total_events = events_to_show('All', 'All')[:events].count

    @distance = {}
    @status = {}
    @event_is_new = {}
    (@confirmed_events + @pending_events).each do |event|
      @distance[event.id] = distance_between_post_codes_in_miles(@prospect.post_code, event.post_code)
      @status[event.id] = get_prospects_event_status(@prospect, event)
    end
    @pending_events = @pending_events.map{|e| @status[e.id] == 'Signed Up' || @status[e.id] == 'In Progress' || @status[e.id] == 'Confirmed' ? [] : e }.flatten

    @status = {}
    (@confirmed_events + @pending_events).each do |event|
      @distance[event.id] = distance_between_post_codes_in_miles(@prospect.post_code, event.post_code)
      @status[event.id] = get_prospects_event_status(@prospect, event)
    end
    @n_active_events = @confirmed_events.length + @pending_events.length
    @job_groups = SharedEventMethods::get_job_groups(@confirmed_events+@pending_events)

    if @prospect.previous_login
      n_new_events = Event.visible.not_finished.where('(show_in_public IS TRUE) AND (date_opened > ?)', @prospect.previous_login).count
    else
      n_new_events = 0
    end

    @allow_sign_up = true if (profile_complete?(@prospect) && @prospect.applicant?) || !(@prospect.applicant?)

    #Library Items
    @library_items = LibraryItem.all.map { |i| [i.name, "/staff/library_item/#{i.id}"] }

    #Terms
    if @prospect.agreed_to_terms?
      # show terms they already agreed to
      @terms  = TextBlock.where("type = 'terms' AND created_at < ?", current_user.datetime_agreement).order('created_at DESC').first.contents
      @prompt = false
      @agreed_on = current_user.datetime_agreement
    else
      # show newest terms and prompt for agreement
      @terms  = TextBlock.where(type: 'terms').order('created_at DESC').first.contents
      @prompt = true
    end
    @terms = @terms.html_safe

    #Change Requests
    if (@cr = ChangeRequest.find_by_prospect_id(current_user.id))
      @pending_bank_details_approval = !@cr.empty?
    end
    @pending_id_approval = @prospect.id_submitted? && !@prospect.id_sighted

    #ID Upload
    @id_view = get_id_view(@prospect)
    @uk_id_view = get_uk_id_view(@prospect)

    #Questions
    if @prospect.questionnaire
      @questionnaire = @prospect.questionnaire
    else
      @questionnaire = Questionnaire.new(prospect_id: @prospect.id)
      @questionnaire.save!
      @prospect.questionnaire = @questionnaire
      @prospect.save!
    end
    @how_heard = ['Friend', 'Web Search', 'Job Centre', 'indeed', 'Gumtree', 'Reed', 'University']

    @interview_calendar = get_interview_calendar(@prospect, 'ONLINE')
    @interview_calendar_inperson = get_interview_calendar(@prospect, 'IN_PERSON')
    @interview = Interview.where(prospect_id: @prospect.id).first

    #Section Visibility
    @profile_complete = profile_complete?(@prospect)

    @training_required = []
    @training_outstanding = []

    @progress_percent = get_progress_percent(@prospect, @interview, @training_outstanding, @n_active_events)

    @past_gigs = Gig.includes(:event).joins(:event).where("gigs.prospect_id = ? AND ((gigs.status = 'Active' AND events.status = 'CLOSED') OR (gigs.status = 'Inactive' AND events.status = 'CLOSED'))", @prospect.id).order(created_at: :desc)
    @gigs_for_rating = @past_gigs.where.not(rating: nil)
    all_gigs_with_rating = Gig.where(prospect_id: @prospect.id).where.not(rating: nil)
    @number_of_ratings = @past_gigs.count
    @average_rating = all_gigs_with_rating.length > 0 ? all_gigs_with_rating.average(:rating).round(2).to_s : (@prospect.rating? ? @prospect.rating.round(2).to_s : '0')
    @average_rating = '0' if @prospect.applicant?
    if @gigs_for_rating.length > 0
      @last_gig_with_rating = @gigs_for_rating.sort_by{|g| g.event.date_end}.last
      @last_gig_with_rating_comment = @last_gig_with_rating.rating_comment
      @display_latest_rating = (@past_gigs.sort_by{|g| g.event.date_end}.last == @last_gig_with_rating)
    end

    @flair_level = get_flair_level(@past_gigs.length)

    #Limit image file uploads to these types:
    @accepted_images = "image/gif, image/jpeg, image/jpg, image/png, application/pdf"
    @accepted_images_profile = "image/gif, image/jpeg, image/jpg, image/png"

    @welcome_text =
      if @prospect.applicant?
        if @profile_complete
          if @interview
            'Looking forward to chatting with you at the interview!'
          else
            'Please sign up for an interview'
          end
        else
          'Please complete your profile to unlock interview sign-up'
        end
      else
        if @profile_complete
          if @prospect.answered_latest_mandatory_questions?
            if @n_active_events > 0
              'Feel free to sign up for more event contracts'
            else
              'Feel free to sign up for event contracts'
            end
          else
            'Please complete the updated questionnaire'
          end
        else
          'Please complete your profile to be eligible to work'
        end
      end

    #@news_items = TextBlock.where(type: 'news', status: 'PUBLISHED')
    #@n_new_news = @news_items.where('date_published > ?', @prospect.previous_login).count
    #@news_items = @news_items.sort_by(&:date_published).reverse

    @show_everything = false #This should always be false. Only set it to true when styling, debugging, etc.
    @interview = Interview.last if @show_everything && !@interview

    @employee = !@prospect.applicant?
    @applicant = @prospect.applicant?
    @applicant_with_interview =      @prospect.applicant? && @interview
    @show_interview =                @prospect.answered_latest_mandatory_questions? && !@prospect.not_applicant
    @show_interview_scheduled        = @interview.present?
    @show_interview_online_signup =  @show_everything || true
    @show_interview_inperson_signup =@show_everyting || !@interview_calendar_inperson.empty?
    @show_profile =                  @show_everything || true
    @show_profile_personal_details = @show_everything || true
    @show_profile_questionnaire =    @show_everything || true
    @show_profile_contact_preferences =  @show_everything || true
    @show_profile_terms =            @show_everything || @employee || @applicant_with_interview || @prospect.answered_latest_mandatory_questions?
    @show_profile_tax_choice =       @show_everything || @employee || @applicant_with_interview || @prospect.answered_latest_mandatory_questions?
    @show_profile_bank_details =     @show_everything || @employee || @applicant_with_interview || @prospect.answered_latest_mandatory_questions?
    @show_profile_id =               @show_everything || @employee || @applicant_with_interview || @prospect.answered_latest_mandatory_questions?
    @show_profile_bar_license =      false #@show_everything || @employee || @applicant_with_interview
    @show_events =                   @show_everything || @employee || (@applicant && @profile_complete)
    @show_training =                 @show_everything || @employee || @applicant_with_interview
    @show_news =                     false #@show_everything || @employee
    @show_library =                  false #@show_everything || @employee
    @detail_submited =               @prospect.has_personal_details? && !(@prospect.answered_latest_mandatory_questions?)

    @training_sports_completed           = @prospect.training_sports
    @training_customer_service_completed = @prospect.training_customer_service
    @training_ethics_completed           = @prospect.training_ethics
    @training_health_safety_completed    = @prospect.training_health_safety
    @training_bar_hospitality_completed  = @prospect.training_bar_hospitality

    (@confirmed_events + @pending_events).each do |e|
      @training_sports_required           ||= e.require_training_sports                   && !@training_sports_completed
      @training_customer_service_required ||= e.require_training_customer_service         && !@training_customer_service_completed
      @training_ethics_required           ||= e.require_training_ethics                   && !@training_ethics_completed
      @training_health_safety_required    ||= e.require_training_health_safety   && !@training_health_safety_completed
      @training_bar_hospitality_required  ||= e.require_training_bar_hospitality && !@training_bar_hospitality_completed
    end

    @show_generic_training_message = !(@training_sports_completed || @training_customer_service_completed || @training_ethics_completed || @training_health_safety_completed || @training_bar_hospitality_completed ||
                                       @training_sports_required  || @training_customer_service_required  || @training_ethics_required  || @training_health_safety_required  || @training_bar_hospitality_required)

    @interview_link_active = @show_interview
    @profile_link_active = @show_profile
    @events_link_active = @show_events
    @training_link_active = @show_training
    @news_link_active = @show_news
    @library_link_active = @show_library

    @interview_badge_count = @show_interview ? 1 : 0
    @profile_badge_count = get_profile_badge_count(@prospect)
    @contracts_badge_count = @n_active_events
    @training_badge_count = [@training_sports_required, @training_customer_service_required, @training_ethics_required, @training_health_safety_required, @training_bar_hospitality_required].select {|t| t}.length
    @news_badge_count = @n_new_news
    @library_badge_count = 0

    @messages = []
    @optional_messages = []
    @messages << (view_context.link_to "Upload a professional photo", "#anchor-me").html_safe if @show_everything || !@prospect.has_photo?
    @messages << (view_context.link_to "Fill in Profile Details", "#anchor-personal-details", class: 'tab_href').html_safe if @show_everything || !@prospect.has_personal_details? && !@prospect.answered_latest_mandatory_questions?
    @messages << (view_context.link_to "Complete Application section", "#anchor-questions", class: 'tab_href').html_safe          if @show_everything || !@prospect.answered_some_questions? || (@prospect.answered_some_questions? && @prospect.needs_to_update_questionnaire?)
#    @messages << (view_context.link_to "Fill in Contact Preferences", "#anchor-contact-preferences", class: 'tab_href').html_safe if @show_everything || !@prospect.has_contact_preferences?
#     @messages << (view_context.link_to "Any Event Contracts Interest You?", "/staff/events").html_safe                      if @show_everything || ((@show_events && !(@n_active_events > 0)) && @applicant)
    @messages << (view_context.link_to "Any work contracts interest you?", "#", class: 'tab_href').html_safe if @show_everything || (@show_interview && !@interview) || @interview && !@employee || (@show_interview && @interview)
    @messages << (view_context.link_to "Adding personal admin optional at this stage.", "#", class: 'tab_href').html_safe if @show_everything || (@show_interview && !@interview) || @interview && !@employee || (@show_interview && @interview)

    @messages << (view_context.link_to "Book your Interview", "#anchor-interview-signup", class: 'tab_href').html_safe if @show_everything || (@show_interview && !@interview) || !@prospect.answered_latest_mandatory_questions?

    new_events_string = n_new_events < 10 ? digit_to_word(n_new_events).capitalize : n_new_events.to_s
    @optional_messages << "Complete your Profile and Application to book an interview" if @show_everything || (@applicant && !@profile_complete)
    @optional_messages << (view_context.link_to "#{new_events_string} new #{'event'.pluralize(n_new_events)} since you last logged in", "/staff/events").html_safe if @show_everything || (@show_events && n_new_events > 0)
    @optional_messages << (view_context.link_to "Feel free to wait until we are your legal employer before uploading your right-to-work ID or other important details.", "#profile").html_safe if @show_everything || (@applicant && @profile_complete) && !@prospect.ready_to_go?
    @optional_messages << (view_context.link_to "Flair training modules are informative, interesting, and offer industry knowledge. ", "#training").html_safe if @show_everything || @applicant_with_interview && @show_generic_training_message
#    @optional_messages << "The news and library sections will be unlocked once you are hired" if @show_everything || @applicant_with_interview
    if @employee
      @messages << (view_context.link_to "New Application questions – indicate job categories of interest and your skill levels.", "#skills-and_interests", class: 'tab_href').html_safe if !@prospect.has_skills_and_interests?
      @messages << (view_context.link_to "Right to Work – ID upload Required.", "#tab-upload-id", class: 'tab_href').html_safe if !@prospect.id_submitted?
      @messages << (view_context.link_to "Please indicate your TAX starter code.", "#tab-tax-choice", class: 'tab_href').html_safe if !@prospect.has_tax_choice?
      @messages << (view_context.link_to "We need your bank details please, wages weekly!", "#tab-bank-details", class: 'tab_href').html_safe if !@prospect.has_bank_details?
      @messages << (view_context.link_to "Please review and confirm your terms.", "#tab-terms", class: 'tab_href').html_safe if !@prospect.agreed_to_terms?
      @messages << (view_context.link_to "Test your industry knowledge – training logs. ", "#training", class: 'tab_href').html_safe if @show_everything || @training_customer_service_required || @training_health_safety_required || @training_ethics_required || @training_sports_required || @training_bar_hospitality_required
    end
    @messages << (view_context.link_to "Check out our ‘Test of Knowledge’ logs.", "#training", class: 'tab_href').html_safe if @interview && (!@training_sports_completed || !@training_customer_service_completed || !@training_ethics_completed || !@training_bar_hospitality_completed)

    update_applicant_status(@prospect, @n_active_events)

    #Temp modifications of data must be done after saving.
    @prospect.bank_account_name ||= "#{@prospect.first_name} #{@prospect.last_name}".upcase
    if @prospect.bank_account_no
      @prospect.bank_account_no.sub!(/\A..../, '****')
      @prospect.bank_account_no.sub!(/\A..../, '****')
    end

    @disabled_skills_interests = !@prospect.applicant? && @prospect.has_skills_and_interests?

    @events = Event.where(status: 'OPEN')


    if request.variant.present?
      return render '/v2/mobile/staff/index'
    end
  end

  def events
    @regions = Region.all.sort_by(&:name).pluck(:name)
    @category = (params[:category] == 'All' || !params[:category].present?) ? nil : params[:category]
    @region =   (params[:region] == 'All'   || !params[:region].present?)   ? nil : params[:region].tr('_', ' ')
    @keyword = params[:keyword].present? ? params[:keyword].to_s : nil
    @show_event = params[:view_event]
    event_results = events_to_show(@category, @region, @keyword)
    events = event_results[:events]
    @empty_message = event_results[:empty_message]

    ##### Staff Zone Specific
    @prospect = current_user
    @distance = {}
    @status = {}
    @event_is_new = {}

    @allow_sign_up = true if (profile_complete?(@prospect) && @prospect.applicant?) || !(@prospect.applicant?)

    new_events = []
    old_events = []
    @week_of_year = 1
    reject_events_ids = @prospect.reject_events.pluck(:event_id)
    events.where.not(id: reject_events_ids).each do |event|
      @distance[event.id] = distance_between_post_codes_in_miles(@prospect.post_code, event.post_code)
      @status[event.id] = get_prospects_event_status(@prospect, event)
      if @prospect.previous_login && event.date_opened && event.date_opened > @prospect.previous_login
        # new_events << event
        old_events << event
        @event_is_new[event.id] = true
      else
        old_events << event
        @event_is_new[event.id] = nil
      end
    end
    featured_events = {}
    # new_featured_events, new_events = new_events.partition { |event| event.show_in_featured }
    old_featured_events, old_events = old_events.partition { |event| event.show_in_featured }
    # featured_events = new_featured_events + old_featured_events
    old_events = old_featured_events + old_events
    old_featured_events.each do |fe|
      featured_events[fe.id] = true
    end

    # flash[:notice] = nil
    # unseen_reject_events = @prospect.reject_events.includes(:event).where(has_seen: false)
    # unless unseen_reject_events.count.zero?
    #   reject_event_names = Event.where(id: unseen_reject_events.pluck(:event_id)).map {|event| "#{event.display_name} #{distance_between_post_codes_in_miles(@prospect.post_code, event.post_code).ceil} Miles Away" }.to_sentence
    #   flash[:notice] = "You have rejected from #{reject_event_names}"
    #   # unseen_reject_events.update(has_seen: true)
    # end

    @deselect_redirect = '/events'
    @job_groups = SharedEventMethods::get_job_groups(events)

    if request.xhr?
      render json: {contents: render_to_string(partial: 'shared/event_list', locals: {featured_events: featured_events, new_events: new_events, events: old_events})}
    else
      old_events = old_events.map{|event| event.jobs.where(include_in_description: true).count > 0 ? event : []}.flatten
      @events = Kaminari.paginate_array(old_events).page(params[:page]&.last).per(10)
      @new_events = nil
      @featured_events = featured_events
      if request.variant.present?
        return render '/v2/mobile/shared/events'
      else
        return render 'v2/shared/events'
      end
    end
  end

  def upload_photo
    if request.post?
      @prospect = current_user

      uploaded = params[:photo]

      if uploaded
        cropData = {
          leftX:       params[:cropLeftX  ].to_i,
          topY:        params[:cropTopY   ].to_i,
          rightX:      params[:cropRightX ].to_i,
          bottomY:     params[:cropBottomY].to_i,
          orientation: params[:orientation].to_i
        }

        target_file_name = "#{@prospect.id}.#{FileUploads::FILE_FORMAT}"
        directory = File.join(Flair::Application.config.shared_dir, 'prospect_photos')
        result  = handle_image_upload(uploaded, directory, target_file_name, Prospect::PROSPECT_THUMBNAIL_SIZE, :max, cropData)
        if result == :ok
          @prospect.update_column(:photo, target_file_name)
          @prospect.update_column(:has_large_photo, true)
        else
          handle_failed_image_upload(result, '/staff')
          return
        end
      end
    end
    respond_to do |format|
      format.html  { redirect_to '/staff#application-skills' }
      format.json  { render json: { path: target_file_name }  }
    end
  end

  def update_personal_details
    if request.post?
      @prospect = current_user

      @prospect.address = params[:prospect][:address] if params[:prospect][:address].present?
      @prospect.address2 = params[:prospect][:address2] if params[:prospect][:address2].present?
      @prospect.gender = params[:prospect][:gender] if params[:prospect][:gender].present?
      params[:date_of_birth] = hash_to_date(params[:date_of_birth]) if params[:date_of_birth].present?
      @prospect.date_of_birth = params[:date_of_birth] if params[:date_of_birth].present?



      @prospect.ni_number = params[:prospect][:ni_number].gsub(/\s+/, '').upcase if params[:prospect][:ni_number].present?
      @prospect.nationality_id = params[:prospect][:nationality_id] if params[:prospect][:nationality_id].present?



      if params[:kid]
        @prospect.kid_datetime = Time.now
        @prospect.save
      else
        @prospect.kid_datetime = nil
        @prospect.save
        flash[:error] = "You need to check 'I Agree' if you agree with Flair's Key Information Document(KID) for PAYE agency workers"
        return redirect_to '/staff'
      end

      if params[:terms]
        @prospect.datetime_agreement = Time.now
        @prospect.save
      else
        @prospect.datetime_agreement = nil
        @prospect.save
        flash[:error] = "You need to check 'I Agree' if you agree to Terms of Engagement for Agency Workers Contract of Services"
        return redirect_to '/staff'
      end

      details = params[:prospect]
      details[:city] = details[:city] == '' ? nil : details[:city]
      # details[:date_of_birth] = hash_to_date(params[:date_of_birth])
      [:home_no, :mobile_no, :emergency_no].each do |k|
        details[k] = details[k].delete("^0-9") if details[k].present?
      end
      details[:ni_number] = details[:ni_number].gsub(/\s+/, '').upcase if details[:ni_number].present?
      details[:email] =     details[:email].gsub(/\s+/, '').downcase    if details[:email].present?

      @prospect.attributes = prospect_params(details)

      @prospect.ni_number = nil unless details[:ni_number].present?
      @prospect.valid? # run default validations
      @prospect.validate_gender_present # run optional validations
      @prospect.validate_ni_number if @prospect.applicant?
      @prospect.validate_nationality
      @prospect.validate_dob_present
      @prospect.validate_address_present
      @prospect.validate_post_code_present
      @prospect.validate_phone_present
      # @prospect.validate_photo

      if @prospect.errors.empty?
        @prospect.save!
        if @prospect.status == "APPLICANT" && @prospect.photo == nil
          return redirect_to '/staff#profile?image=noImage'
        elsif @prospect.status == "APPLICANT"
          return redirect_to '/staff#application'
        else
          return redirect_to '/staff'
        end
      else
        flash[:error] = @prospect.errors.full_messages.to_sentence
      end
    end
    return redirect_to '/staff'
  end

  def check_email
    if params[:email] != current_user.email
      prospect = Prospect.find_by(email: params[:email])

      if prospect
        render json: {check: "true"}
      else
        render json: {check: "false"}
      end
    else
      render json: {check: "false"}
    end
  end

  def update_contact_preferences
    if request.post?
      @prospect = current_user
      details = params[:prospect]

      @prospect.attributes = prospect_params(details)

      @prospect.valid? # run default validations
      @prospect.validate_contact_preference #run optional validations
      @prospect.validate_preferred_contact_time
      @prospect.validate_prefers_skype
      @prospect.validate_prefers_facetime
      @prospect.validate_prefers_phone

      if @prospect.errors.empty?
        @prospect.save!
      else
        flash[:error] = @prospect.errors.full_messages.to_sentence
      end
    end
    redirect_to '/staff#profile'
  end

  def update_questions
    if request.post?
      # if !current_user.v2_applications_done?
      #   flash[:job_board_title] = "Application form done!"
      #   flash[:job_board] = "Now to selecting a convenient time we can contact you to discuss your skills and work preferences."
      #   flash[:job_board_1] = 'Let’s get you in our team and working.'
      #   flash[:button_title] = "Got it"
      # end
      prospect = current_user
      params[:questionnaire][:describe_yourself] = "#{params["describe_yourself_one"]} #{params["describe_yourself_two"]} #{params["describe_yourself_three"]} #{params["describe_yourself_four"]} #{params["describe_yourself_five"]}"
      answers = params[:questionnaire].except(:describe_yourself_one, :describe_yourself_two, :describe_yourself_three, :describe_yourself_four, :describe_yourself_five)
      questionnaire = prospect.questionnaire
      prospect.city_of_study = params[:questionnaire][:city_of_study]
      questionnaire.city_of_study = params[:questionnaire][:city_of_study]
      questionnaire.friends_connection = params[:friends_connection]
      questionnaire.recommended_you = params[:recommended_you]

      ######
      ######  WORK EXPERIENCE
      ######
      #Retrieve Dates and put them in the answers
      #We use select_date instead of f.select_date because the resulting hash is more straightforward for parsing
      # if request.variant.present?
      #   answers[:job1_date_start] = params[:questionnaire][:job1_date_start]
      #   answers[:job1_date_finish] = params[:job1_tick] == nil ? params[:questionnaire][:job1_date_finish] : nil
      #   answers[:job2_date_start] = params[:questionnaire][:job2_date_start]
      #   answers[:job2_date_finish] = params[:job2_tick] == nil ? params[:questionnaire][:job2_date_finish] : nil
      # else
      #   answers[:job1_date_start] = hash_to_date(params[:job1_date_start])
      #   answers[:job1_date_finish] = params[:job1_tick] == nil ? hash_to_date(params[:job1_date_finish]) : nil
      #   answers[:job2_date_start] = hash_to_date(params[:job2_date_start])
      #   answers[:job2_date_finish] = params[:job2_tick] == nil ? hash_to_date(params[:job2_date_finish]) : nil
      # end

      answers[:job1_date_start] = hash_to_date(params[:job1_date_start])
      answers[:job1_date_finish] = params[:job1_tick] == nil ? hash_to_date(params[:job1_date_finish]) : nil
      answers[:job2_date_start] = hash_to_date(params[:job2_date_start])
      answers[:job2_date_finish] = params[:job2_tick] == nil ? hash_to_date(params[:job2_date_finish]) : nil

      answers[:has_bar_and_hospitality] ||= questionnaire.has_bar_and_hospitality

      answers[:has_sport_and_outdoor] ||= questionnaire.has_sport_and_outdoor

      answers[:has_promotional_and_street_marketing] ||= questionnaire.has_promotional_and_street_marketing

      answers[:has_reception_and_office_admin] ||= questionnaire.has_reception_and_office_admin

      answers[:has_festivals_and_concerts] ||= questionnaire.has_festivals_and_concerts

      answers[:has_merchandise_and_retail] ||= questionnaire.has_merchandise_and_retail


      #Massage Answers
      answers[:heard_about_flair] = params[:heard_about_flair_other_text] if (answers[:heard_about_flair] == 'Other' && params[:heard_about_flair_other_text])
      questionnaire.boolean_question_fields.each do |f|
        answers[f] = (answers[f] == '1') if answers[f] == '0' || answers[f] == '1'
      end

      questionnaire.question_fields.each do |f|
        if answers[f] != questionnaire[f]
          questionnaire[f] = answers[f]
        end
      end

      if questionnaire.sclps_2_hr_training
        prospect.bar_license_type = "SCLPS_2_HR_TRAINING"
      end

      if questionnaire.scottish_personal_licence_qualification
        prospect.bar_license_type = "SCOTTISH_PERSONAL_LICENSE"
      end

      if questionnaire.english_personal_licence_qualification
        prospect.bar_license_type = "ENGLISH_PERSONAL_LICENSE"
      end

      if !questionnaire.sclps_2_hr_training && !questionnaire.scottish_personal_licence_qualification && !questionnaire.english_personal_licence_qualification
        prospect.bar_license_type = nil
      end


      #Save related prospect fields
      prospect.good_bar = questionnaire.interested_in_bar != nil
      prospect.good_sport = questionnaire.interested_in_marshal != nil
      prospect.good_management = questionnaire.team_leader_experience != nil
      prospect.good_promo = questionnaire.promotions_experience != nil
      prospect.bar_experience = params[:bar_experience] if params[:bar_experience].present?

      prospect.has_bar_and_hospitality = questionnaire.has_bar_and_hospitality != nil
      prospect.has_sport_and_outdoor = questionnaire.has_sport_and_outdoor != nil
      prospect.has_promotional_and_street_marketing = questionnaire.has_promotional_and_street_marketing != nil
      prospect.has_merchandise_and_retail = questionnaire.has_merchandise_and_retail != nil
      prospect.has_reception_and_office_admin = questionnaire.has_reception_and_office_admin != nil
      prospect.has_festivals_and_concerts = questionnaire.has_festivals_and_concerts != nil

      prospect.has_bar_management_experience = questionnaire.bar_management_experience == "0" || questionnaire.bar_management_experience == false ? false : true
      prospect.has_staff_leadership_experience = questionnaire.staff_leadership_experience == "0" || questionnaire.staff_leadership_experience == false ? false : true
      prospect.has_festival_event_bar_management_experience = questionnaire.festival_event_bar_management_experience == "0" || questionnaire.festival_event_bar_management_experience == false ? false : true
      prospect.has_event_production_experience = questionnaire.event_production_experience == "0" || questionnaire.event_production_experience == false ? false : true


      prospect.bar_skill = questionnaire.has_bar_and_hospitality
      prospect.promo_skill = questionnaire.has_promotional_and_street_marketing
      prospect.retail_skill = questionnaire.has_merchandise_and_retail
      prospect.office_skill = questionnaire.has_reception_and_office_admin
      prospect.festival_skill = questionnaire.has_festivals_and_concerts
      prospect.sport_skill = questionnaire.has_sport_and_outdoor

      prospect.staff_leader_skill = questionnaire.staff_leadership_experience == "0" || questionnaire.staff_leadership_experience == false ? false : true
      prospect.bar_manager_skill = questionnaire.bar_management_experience == "0" || questionnaire.bar_management_experience == false ? false : true

      #Validations
      questionnaire.valid?
      prospect.valid?

      # check if user remove 2nd job
      if answers[:job2_position] == nil
        questionnaire.job2_position = nil
        questionnaire.job2_company = nil
        questionnaire.job2_date_start = nil
        questionnaire.job2_date_finish = nil
        questionnaire.job2_description = nil
      end

      # check if user remove reference
      if answers[:referee_name] == nil
        questionnaire.referee_name = nil
        questionnaire.referee_position = nil
        questionnaire.referee_company = nil
        questionnaire.referee_email = nil
      end

      if current_user.questionnaire.skills == {}
        current_user.questionnaire.skills = {:sports_outdoors=>nil, :events_festivals=>nil, :promotional=>nil, :bar=>nil, :hospitality=>nil, :logistics=>nil, :office=>nil, :retail=>nil}
      end
      if prospect.errors.empty? && questionnaire.errors.empty?
        prospect.save!
        questionnaire.save!
      else
        errors = ''
        errors += questionnaire.errors.full_messages.to_sentence if questionnaire.errors
        errors += prospect.errors.full_messages.to_sentence if prospect.errors
        flash.now[:error] = errors
      end
    end

    respond_to do |format|
      format.js {render json: {success: true}}
      if prospect.present?
        if prospect.status == 'APPLICANT'
          format.html {redirect_to '/staff#interview'}
        else
          format.html {redirect_to '/staff#application'}
        end
      else
        format.html {redirect_to '/staff'}
      end
    end
  end

  def update_question_skills
    if request.post?
      prospect = current_user
      questionnaire = prospect.questionnaire
      answers = params[:questionnaire]
      # CATEGORIES
      if answers
        questionnaire.has_sport_and_outdoor = answers[:has_sport_and_outdoor]
        questionnaire.has_festivals_and_concerts = answers[:has_festivals_and_concerts]
        questionnaire.has_promotional_and_street_marketing = answers[:has_promotional_and_street_marketing]
        questionnaire.has_bar = answers[:has_bar]
        questionnaire.has_bar_and_hospitality = answers[:has_bar_and_hospitality]
        questionnaire.has_reception_and_office_admin = answers[:has_reception_and_office_admin]
        questionnaire.has_merchandise_and_retail = answers[:has_merchandise_and_retail]
        questionnaire.has_logistics = answers[:has_logistics]

        prospect.bar_skill = questionnaire.has_bar
        prospect.promo_skill = questionnaire.has_promotional_and_street_marketing
        prospect.retail_skill = questionnaire.has_merchandise_and_retail
        prospect.office_skill = questionnaire.has_reception_and_office_admin
        prospect.festival_skill = questionnaire.has_festivals_and_concerts
        prospect.sport_skill = questionnaire.has_sport_and_outdoor
        prospect.hospitality_skill = questionnaire.has_bar_and_hospitality
        prospect.warehouse_skill = questionnaire.has_logistics
      else
        questionnaire.has_sport_and_outdoor = nil
        questionnaire.has_festivals_and_concerts = nil
        questionnaire.has_promotional_and_street_marketing = nil
        questionnaire.has_bar = nil
        questionnaire.has_bar_and_hospitality = nil
        questionnaire.has_reception_and_office_admin = nil
        questionnaire.has_merchandise_and_retail = nil
        questionnaire.has_logistics = nil

        prospect.bar_skill = nil
        prospect.promo_skill = nil
        prospect.retail_skill = nil
        prospect.office_skill = nil
        prospect.festival_skill = nil
        prospect.sport_skill = nil
        prospect.hospitality_skill = nil
        prospect.warehouse_skill = nil
      end

      prospect.save

      questionnaire.save

      # SUB CATEGORIES
      skills_object = {
        "sports_outdoors": params[:sports],
        "events_festivals": params[:events],
        "promotional": params[:promotional],
        "bar": params[:bar],
        "hospitality": params[:hospitality],
        "logistics": params[:logistics],
        "office": params[:office],
        "retail": params[:retail],
      }

      questionnaire.skills = skills_object

      questionnaire.save
    end
    if answers
      redirect_to '/staff#application-form'
    else
      flash[:landing_page] = "Select a skill."
      flash[:title] = "Skill not selected."
      flash[:button] = "Close"
      flash[:returning] = "true"
      redirect_to '/staff#application-skills'
    end
  end

  def update_question_skills_sub
    if request.post?
      prospect = current_user
      questionnaire = prospect.questionnaire

      case params[:category]
      when "sports_outdoors"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:sports_outdoors] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:sports_outdoors] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:sports_outdoors] || []
          skills_array << params[:skill]
          questionnaire.skills[:sports_outdoors] = skills_array
          questionnaire.save
        end
      when "events_festivals"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:events_festivals] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:events_festivals] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:events_festivals] || []
          skills_array << params[:skill]
          questionnaire.skills[:events_festivals] = skills_array
          questionnaire.save
        end
      when "promotional"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:promotional] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:promotional] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:promotional] || []
          skills_array << params[:skill]
          questionnaire.skills[:promotional] = skills_array
          questionnaire.save
        end
      when "bar"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:bar] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:bar] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:bar] || []
          skills_array << params[:skill]
          questionnaire.skills[:bar] = skills_array
          questionnaire.save
        end
      when "hospitality"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:hospitality] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:hospitality] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:hospitality] || []
          skills_array << params[:skill]
          questionnaire.skills[:hospitality] = skills_array
          questionnaire.save
        end
      when "logistics"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:logistics] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:logistics] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:logistics] || []
          skills_array << params[:skill]
          questionnaire.skills[:logistics] = skills_array
          questionnaire.save
        end
      when "office"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:office] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:office] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:office] || []
          skills_array << params[:skill]
          questionnaire.skills[:office] = skills_array
          questionnaire.save
        end
      when "retail"
        if params[:remove] == "true"
          skills_array = questionnaire.skills[:retail] || []
          skills_array.delete(params[:skill])
          questionnaire.skills[:retail] = skills_array
          questionnaire.save
        else
          skills_array = questionnaire.skills[:retail] || []
          skills_array << params[:skill]
          questionnaire.skills[:retail] = skills_array
          questionnaire.save
        end
      else

      end
    end
  end

  def update_nationality
    @prospect = current_user
    @prospect.nationality_id = params[:prospect][:nationality_id]
    @prospect.validate_nationality

    if @prospect.errors.empty?
      @prospect.save!
      render partial: get_id_view(@prospect)
    else
      flash[:error] = @prospect.errors.full_messages.to_sentence
      redirect_to '/staff#profile'
    end
  end

  def check_non_uk
    if request.variant.present?
      render partial: 'v2/mobile/staff/profile_upload_id_others_work_visa'
    else
      render partial: 'v2/staff/profile_upload_id_others_work_visa'
    end
  end

  def update_uk_id_type
    @prospect = current_user
    @prospect.id_type = params[:prospect][:uk_id_type] if params[:prospect] && params[:prospect][:uk_id_type]

    if @prospect.errors.empty?
      @prospect.save!
      render partial: get_uk_id_view(@prospect)
    else
      flash[:error] = @prospect.errors.full_messages.to_sentence
      redirect_to 'staff#application-identification'
    end
  end

  def update_bank_details
    if request.post?
      @prospect = current_user
      params[:prospect][:bank_account_name].upcase! if params[:prospect][:bank_account_name].present?
      params[:prospect][:bank_account_no] = params[:prospect][:bank_account_no].delete("^0-9*")
      params[:prospect][:bank_sort_code] = params[:prospect][:bank_sort_code].delete("^0-9*")

      if @prospect.has_bank_details?
        cr = ChangeRequest.where(prospect_id: current_user.id).first_or_create
        [:bank_account_name, :bank_account_no, :bank_sort_code].each do |k|
          # we show an already-entered number with *'s for the first 4 digits
          # if they click the 'Save' button without editing the starred bank account number,
          # DON'T actually submit a change request for the unedited bank account number!
          # next if params[:prospect][k] =~ /\*/
          if params[:prospect][k] =~ /\*/
            flash[:notice] = "Please retype your whole bank account no. to update."
            next
          end
          if params[:prospect][k] != @prospect[k]
            cr[k] = params[:prospect][k]
          end
        end
        unless cr.valid? && cr.save
          flash[:error] = cr.errors.full_messages.to_sentence
        end
      else
        @prospect.bank_account_name = params[:prospect][:bank_account_name]
        @prospect.bank_account_no = params[:prospect][:bank_account_no] unless params[:prospect][:bank_account_no] =~ /\*/
        @prospect.bank_sort_code = params[:prospect][:bank_sort_code] unless params[:prospect][:bank_sort_code] =~ /\*/
        @prospect.bank_account_name = nil if @prospect.bank_account_name == ''
        unless @prospect.save
          flash[:error] = @prospect.errors.full_messages.to_sentence
        end
      end
    end
    redirect_to '/staff#application-bank'
  end

  def upload_uk_passport
    @prospect = current_user
    render partial: 'upload_uk_passport'
  end
  def upload_uk_birth_certificate
    @prospect = current_user
    render partial: 'upload_uk_birth_certificate'
  end
  def upload_uk_passport_images
    handle_scanned_id_uploads('Passport', 'UK Passport', 'picture_page' => params[:picture_page], 'front_cover' => params[:front_cover])
  end
  def upload_eu_passport
    handle_scanned_id_uploads('Passport', 'EU Passport', 'picture_page' => params[:picture_page], 'front_cover' => params[:front_cover])
  end
  def upload_birth_certificate
    handle_scanned_id_uploads('Birth Certificate', 'BC+NI', 'birth_certificate' => params[:birth_certificate], 'ni_document' => params[:ni_document], 'photo_id' => params[:photo_id])
  end
  def upload_passport_and_visa
    share_code = params[:share_code].gsub(/[-_]/, '').upcase 

    unless current_user.update(share_code: share_code)
      flash[:error] = current_user.errors.full_messages.to_sentence
      return redirect_to '/staff#application-identification'
    end

    scans = {'picture_page' => params[:picture_page], 'front_cover' => params[:front_cover]}
    scans['brp_front']    = params[:brp_front]     if params[:brp_front]
    scans['brp_back']     = params[:brp_back]      if params[:brp_back]
    scans['working_visa'] = params[:working_visa]  if params[:working_visa]
    handle_scanned_id_uploads('Passport and Work Visa', 'Work/Residency Visa', scans)
  end
  
  def update_share_code
    current_user.share_code = params[:share_code].gsub(/[-_]/, '').upcase 
    current_user.visa_indefinite = params[:visa_indefinite].present?
    expiry = if params[:visa_expiry].as_json.length == 3
               hash_to_date(params[:visa_expiry])
             else
               params[:visa_expiry]
             end

    if params[:visa_indefinite].blank? && expiry.blank?
      flash[:error] = 'You must fill in your visa expiry'
      return redirect_to '/staff#application-identification'
    end

    current_user.visa_expiry = expiry

    current_user.id_sighted = nil
    current_user.id_type = 'Work/Residency Visa'
    current_user.id_submitted_date = Date.today()
    
    unless current_user.save
      flash[:error] = current_user.errors.full_messages.to_sentence
    end
    
    redirect_to '/staff#application-identification'
  end

  def update_tax_choice
    if request.post?
      @prospect = current_user

      params[:tax_choice] = params[:tax_choice_A] || params[:tax_choice_B] || params[:tax_choice_C]
      params[:student_loan] = params[:student_loan_true] || params[:student_loan_false]

      if params[:tax_choice] == nil
        flash[:error] = 'Please choose statement A, B, or C.'
      else
        @prospect.date_tax_choice = Date.today
        @prospect.tax_choice = params[:tax_choice]
        @prospect.student_loan = (params[:student_loan] == 'true')
        unless @prospect.valid? && @prospect.save
          flash[:error] = @prospect.errors.full_messages.to_sentence
        end
      end
    end
    if params[:tax_choice] == nil
      redirect_to '/staff#application-tax'
    else
      redirect_to '/staff#application-bank'
    end

  end

  def terms
    if request.post?
      @prospect = current_user

      current_user.datetime_agreement = Time.now
      current_user.save!

      render json: 'Success'
    else
      redirect_to '/staff'
    end
  end

  def kid
    if request.post?
      @prospect = current_user
      current_user.kid_datetime = Time.now
      current_user.save!

      render json: 'Success'
    else
      redirect_to '/staff'
    end
  end

  def select_event
    if request.post?
      prospect = current_user
      event = Event.find(params[:event_id])
      job = params[:job] == "" ? nil : params[:job]
      if ['OPEN', 'HAPPENING'].include?(event.status)
        gr = GigRequest.where(prospect_id: prospect.id, event_id: event.id, job_id: job).first_or_create
        unless gr.validate
          flash[:error] = gr.errors.full_messages.to_sentence
        end

        if prospect.status == 'SLEEPER'
        prospect.status = 'EMPLOYEE'
        unless prospect.save
          flash[:error] = prospect.errors.full_messages.to_sentence
        end
        end
      end
      return render json: {status: :success}
      flash[:job_board_title] = "Thank you for your application"
      flash[:job_board] = "Keep an eye out for further communication from us as the start date draws closer. We look forward to potentially working with you."
      flash[:button_title] = "GOT IT"
    end
    return redirect_to '/staff/events'
  end

  def deselect_event
    @event = Event.find(params[:id])
    prospect = Prospect.find(current_user.id)
    status = get_prospects_event_status(current_user, @event)

    params[:redirect] ||= "/staff/events"

    flash[:alert] = "You have Successfully cancelled your application to this event - see you at others."

    if gig_request = GigRequest.where(prospect_id: current_user.id, event_id: @event.id).first
      if gig = gig_request.gig
        if status != 'Confirmed'
          if @event.date_callback_due && Date.today > @event.date_callback_due
            flash[:error] = "Ooops we too close to the confirmed booking. Can you contact the office direct so we can fill your shifts quickly. Call us on #{TextBlock['company-tel']} or
            <br>
            e-mail work@flairpeople.com".html_safe
            redirect_to params[:redirect]
            return
          end

          destroy_gig(gig)
        else
          flash[:error] = "Ooops we too close to the confirmed booking. Can you contact the office direct so we can fill your shifts quickly. Call us on #{TextBlock['company-tel']} or
          <br>
          e-mail work@flairpeople.com".html_safe
          redirect_to params[:redirect]
          return
        end
      end

      gig_request.destroy

    if params[:redirect] == "/staff"
      flash[:redirect] = "jobs-applied"
    end
    # In some cases, a person may be hired directly for an Event without submitting a Gig Request through the web site...
    # Perhaps they may call into the office on the phone and ask to work
    # elsif gig = Gig.where(prospect_id: current_user.id, event_id: @event.id, status: 'Active').first
    elsif gig = Gig.where(prospect_id: current_user.id, event_id: @event.id).first
      if status != 'Confirmed'
        if (@event.date_callback_due && Date.today > @event.date_callback_due) || (@event.date_callback_due == nil && (gig.assignments.map{|asgn| asgn.shift.date >= Date.today ? asgn : []}.flatten.count > 0))
          flash[:error] = "Ooops we too close to the confirmed booking. Can you contact the office direct so we can fill your shifts quickly. Call us on #{TextBlock['company-tel']} or
          <br>
          e-mail work@flairpeople.com".html_safe
        else
          destroy_gig(gig)
        end
      else
        flash[:error] = "Ooops we too close to the confirmed booking. Can you contact the office direct so we can fill your shifts quickly. Call us on #{TextBlock['company-tel']} or
        <br>
        e-mail work@flairpeople.com".html_safe
      end

      if params[:redirect] == "/staff"
        flash[:redirect] = "jobs"
      end

      redirect_to params[:redirect]
      return
    end

    redirect_to params[:redirect]
  end

  def library_item
    item = LibraryItem.find(params[:id])
    file_path = File.join(Flair::Application.config.shared_dir, 'library', item.filename)
    send_file(file_path, filename: item.filename)
    headers['Content-Length'] = File.size(file_path)
  end

  def contact
    @errors = Hash.new { |h,k| h[k] = [] }

    if request.post?
      [:subject, :message].each { |k| params[k].strip! if params[k] }
      @errors[:subject] << "Subject can't be blank" if params[:subject].blank?
      @errors[:subject] << "Subject can't be more than 300 characters" if params[:subject].size > 300
      @errors[:message] << "Message can't be blank" if params[:message].blank?
      @errors[:message] << "Message can't be more than 5000 characters" if params[:message].size > 5000

      if @errors.empty?
        send_mail(PublicMailer.contact_submission(current_user.name + ' (REGISTERED PROSPECT)', current_user.email, current_user.mobile_no, params[:subject], params[:message]))
        flash[:notice] = 'Thank you! Your message has been delivered.'
        redirect_to "/staff"
        return
      else
        @subject, @message = params[:subject], params[:message]
      end
    end

    @address = TextBlock['company-address']
    @tel     = TextBlock['company-tel']
    @mobile  = TextBlock['company-mobile']
  end

  def sign_up_for_interview
    if params[:interview_block]
      if params[:telephone_call_interview] != "0" || params[:video_call_interview] != "0"
        interview_block_id = params[:interview_block].split(".")[0]
        interview_block_time = params[:interview_block].split(".")[1]
        if InterviewBlock.exists?(interview_block_id)

          # remove applicant from the previous interview if this is resched
          old_interview = Interview.where(prospect_id: current_user.id).first
          if old_interview
            old_interview_block = old_interview.interview_block
            old_time_type = old_interview.time_type
            case old_time_type
            when "MORNING"
              old_interview_block.update(morning_interviews: old_interview_block.morning_interviews - 1)
            when "AFTERNOON"
              old_interview_block.update(afternoon_interviews: old_interview_block.afternoon_interviews - 1)
            when "EVENING"
              old_interview_block.update(evening_interviews: old_interview_block.evening_interviews - 1)
            else

            end
          end


          block = InterviewBlock.find(interview_block_id)

          case interview_block_time
          when "MORNING"
            if block.morning_applicants > block.morning_interviews
              interview = Interview.where(prospect_id: current_user.id).first_or_initialize
              interview.interview_block_id = block.id
              interview.interview_slot_id = block.interview_slots.first.id
              interview.telephone_call_interview = params[:telephone_call_interview]
              interview.video_call_interview = params[:video_call_interview]
              interview.time_type = "MORNING"
              interview.save!
              send_interview_email(interview)

              block.update(morning_interviews: block.morning_interviews + 1)
            else
              flash[:notice] = 'Sorry! That interview block has just become full. Please select another time.'
            end
          when "AFTERNOON"
            if block.afternoon_applicants > block.afternoon_interviews
              interview = Interview.where(prospect_id: current_user.id).first_or_initialize
              interview.interview_block_id = block.id
              interview.interview_slot_id = block.interview_slots.first.id
              interview.telephone_call_interview = params[:telephone_call_interview]
              interview.video_call_interview = params[:video_call_interview]
              interview.time_type = "AFTERNOON"
              interview.save!
              send_interview_email(interview)

              block.update(afternoon_interviews: block.afternoon_interviews + 1)
            else
              flash[:notice] = 'Sorry! That interview block has just become full. Please select another time.'
            end
          when "EVENING"
            if block.evening_applicants > block.evening_interviews
              interview = Interview.where(prospect_id: current_user.id).first_or_initialize
              interview.interview_block_id = block.id
              interview.interview_slot_id = block.interview_slots.first.id
              interview.telephone_call_interview = params[:telephone_call_interview]
              interview.video_call_interview = params[:video_call_interview]
              interview.time_type = "EVENING"
              interview.save!
              send_interview_email(interview)

              block.update(evening_interviews: block.evening_interviews + 1)
            else
              flash[:notice] = 'Sorry! That interview block has just become full. Please select another time.'
            end
          else

          end
        else
          flash[:notice] = 'Sorry! That interview block has just become unavailable. Please select another time.'
        end
      else
        flash[:notice] = 'You need to select the method for your interview.'
        flash[:title] = "Book an Interview"
        flash[:button_title] = "Book Interview"
      end
    else
      flash[:notice] = 'You need to select the date you want your interview to be scheduled and the method of interviewing, either through video call or telephone call.'
      flash[:title] = "Book an Interview"
      flash[:button_title] = "Okay"
    end
    redirect_to '/staff#interview?popup=noPopup'
  end

  def cancel_interview
    interview = Interview.where(prospect_id: current_user.id).first
    time_type = interview.time_type
    block = interview.interview_block
    case time_type
    when "MORNING"
      block.update(morning_interviews: block.morning_interviews - 1)
    when "AFTERNOON"
      block.update(afternoon_interviews: block.afternoon_interviews - 1)
    when "EVENING"
      block.update(evening_interviews: block.evening_interviews - 1)
    else

    end
    Interview.where(prospect_id: current_user.id).destroy_all
    redirect_to '/staff#interview'
  end

  def refresh_online_interview_tab
    @prospect = current_user
    @interview_calendar = get_interview_calendar(current_user, 'ONLINE')
    @interview = Interview.where(prospect_id: @prospect.id).first
    render json: {contents: render_to_string(partial: 'interview_online_signup')}
  end

  def get_hired_status
    render json: {status: current_user.status}
  end

  def get_training_module
    if lookup_context.template_exists?("training_#{params[:module]}", 'staff', true)
      prop = "training_#{params[:module]}_index"
      render json: {
        module: render_to_string(partial: "training_#{params[:module]}"),
        index: current_user.respond_to?(prop) ? current_user[prop] : 0
      }
    else
      render json: { module: render_to_string(partial: 'training_coming_soon'), index: 0 }
    end
  end

  def mark_training_module_complete
    prospect = current_user
    prop = 'training_' + params[:module]
    if prospect.respond_to?(prop)
      prospect[prop] = true
      prospect.save
      render json: {marked: true}
    else
      render json: {marked: false}
    end
  end

  def update_training_module_progress
    prospect = current_user
    prop = 'training_' + params[:module] + '_index'
    if prospect.respond_to?(prop)
      prospect[prop] = params[:index]
      prospect.save
      render json: {updated: true}
    else
      render json: {updated: false}
    end
  end

  def refresh_events
    event_results = events_to_show(params[:category], params[:region])
    events = event_results[:events]
    @empty_message = event_results[:empty_message]

    ##### Staff Zone Specific
    @prospect = current_user
    @distance = {}
    @status = {}
    @event_is_new = {}

    @allow_sign_up = true if (profile_complete?(@prospect) && @prospect.applicant?) || !(@prospect.applicant?)

    new_events = []
    old_events = []
    @week_of_year = 1

    events.each do |event|
      @distance[event.id] = distance_between_post_codes_in_miles(@prospect.post_code, event.post_code)
      @status[event.id] = get_prospects_event_status(@prospect, event)
      if @prospect.previous_login && event.date_opened && event.date_opened > @prospect.previous_login
        new_events << event
        @event_is_new[event.id] = true
      else
        old_events << event
        @event_is_new[event.id] = nil
      end
    end
    new_featured_events, new_events = new_events.partition { |event| event.show_in_featured }
    old_featured_events, old_events = old_events.partition { |event| event.show_in_featured }

    @deselect_redirect = '/events'
    @job_groups = SharedEventMethods::get_job_groups(events)

    render json: {contents: render_to_string(partial: 'shared/event_list', locals: {featured_events: old_featured_events + new_featured_events, new_events: new_events, events: old_events})}
  end

  def refresh_contracts
    @prospect = current_user
    confirmed_events = Event.includes(:jobs, :region).find(Gig.joins(:event).where('gigs.prospect_id = ? AND events.date_end >= ? AND gigs.status = ?', @prospect.id, Date.today, 'Active').pluck('gigs.event_id')).sort_by(&:next_active_date)
    pending_events   = Event.includes(:jobs, :region).find(GigRequest.joins(:event).where('gig_requests.prospect_id = ? AND gig_requests.gig_id IS NULL AND events.date_end >= ?', @prospect.id, Date.today).pluck(:event_id)).sort_by(&:next_active_date)
    events = confirmed_events+pending_events
    @distance = {}
    @status = {}
    @event_is_new = {}

    @allow_sign_up = true if (profile_complete?(@prospect) && @prospect.applicant?) || !(@prospect.applicant?)

    events.each do |event|
      @distance[event.id] = distance_between_post_codes_in_miles(@prospect.post_code, event.post_code)
      @status[event.id] = get_prospects_event_status(@prospect, event)
      if @prospect.previous_login && event.date_opened && event.date_opened > @prospect.previous_login
        @event_is_new[event.id] = true
      else
        @event_is_new[event.id] = nil
      end
    end

    @deselect_redirect = 'staff/events'
    @job_groups = SharedEventMethods::get_job_groups(events)

    render json: {
      upcoming: render_to_string(partial: 'shared/event_list', locals: {events: confirmed_events}),
      pending:  render_to_string(partial: 'shared/event_list', locals: {events: pending_events})
    }
  end

  def check_if_logged_in
    #authenticate_user! Will return false if user is not logged in
    render json: { logged_in: true}
  end

  def relogin
    params[:login_email] = (params[:login_email] || '').gsub(/\s+/, '').downcase
    email, password = params[:login_email], params[:login_password]
    @logged_in = login_as_prospect(email, password)
    if @logged_in == :success
      current_user.previous_login = current_user.last_login
      current_user.last_login = Date.today
      current_user.save!
    end
    respond_to do |format|
      format.js
    end
  end

  # Updates the account with a new password
  def set_password
    if request.get?

      if request.variant.present?
        return render 'v2/mobile/staff/set_password'
      else
        return render 'v2/staff/set_password'
      end
    end
    if request.post?
      # Always check to see if the params are present, if not then gracefully fail.
      unless params.dig(:password) and params.dig(:password_confirm)
        ExceptionMailer.notify("StaffController#set_password", "The params are missing again. Params: #{params.permit!.to_h} USER_AGENT: #{request.user_agent}").deliver_later
        flash.now[:error] = "We had trouble finding the passwords you entered, please try again. If you continue to experience this error please contact us."
        return
      end


      # Params are present, carry on...
      password, confirmation = params[:password].strip, params[:password_confirm].strip
      if password == confirmation
        if Account.password_valid?(password)
          current_user.account.password = password
          current_user.account.save!
          flash[:notice] = 'Password updated!'
          redirect_to '/staff'
        else
          flash.now[:error] = Account.why_invalid?(password)
        end
      else
        flash.now[:error] = "The passwords you entered don't match. Please enter the same password twice."
      end
    end
  end

  def deactivate_account
    current_user.status = 'DEACTIVATED' unless current_user.status == 'HAS_BEEN'
    current_user.save!

    upcoming_gigs = current_user.gigs.includes(:gig_assignments).joins(:event).where('events.date_start > ?', Date.today)
    upcoming_gigs.each { |gig| destroy_gig(gig) }

    current_user.gig_requests.destroy_all

    if Gig.where(prospect_id: current_user.id).any?
      send_mail(StaffMailer.employee_deactivated_account_contracts_worked(current_user, upcoming_gigs))
      flash[:notice] = 'Done! We will not contact you about upcoming events. If you ever want to work for Flair Events again, just return to this site to reactivate your account.'
    else
      send_mail(StaffMailer.employee_deactivated_account_no_contracts_worked(current_user, upcoming_gigs))
      flash[:notice] = 'Done! We will not contact you about upcoming events. If you ever want to work for Flair Events again, just return to this site to re-register.'
      id_to_destroy = current_user.id
    end

    logout_account

    Prospect.find(id_to_destroy).destroy! if id_to_destroy

    redirect_to '/'
  end

  def reactivate_account
    if current_user.deactivated?
      current_user.status = 'EMPLOYEE'
      current_user.save
      flash[:notice] = "Welcome back! Your account has been reactivated."
    end
    redirect_to '/staff'
  end

  def logout
    unseen_reject_events = current_user.reject_events.includes(:event).where(has_seen: false, has_seen_2: true)
    if unseen_reject_events.count > 0
      unseen_reject_events.update(has_seen: true)
    end
    logout_account
    redirect_to '/login'
  end

  def unsubscribe
    # The user may have got here by clicking a link in an e-mail; we do not go
    #   through the usual authenticate-by-cookie flow in that case
    if params[:token]
      unless @account = Account.find_by_unsubscribe_token(params[:token])
        ensure_prospect_logged_in
      end
      if current_user.is_a?(Officer)
        flash[:notice] = "Employees of Flair Events may not unsubscribe from e-mail."
        redirect_to '/'
      end
    else
      # If there is no unsubscribe token present, go through the usual authentication
      ensure_prospect_logged_in
    end

    if request.post?
      if params[:desired_action] == 'deactivate'
        deactivate_account
      elsif params[:desired_action] == 'no_marketing'
        current_user.send_marketing_email = false
        current_user.save!
        flash[:title] = "Done!"
        flash[:notice] = <<-MESSAGE
          We will not send you any unsolicited e-mails informing you of new job opportunities.
          If you have any concerns about other work-related e-mails which we are sending you, please contact us at 0161 241 2441 or work@flairevents.co.uk.
        MESSAGE
        redirect_to '/staff'
      elsif params[:desired_action] == 'all_email'
        current_user.send_marketing_email = true
        current_user.save!
        flash[:title] = "Done!"
        flash[:notice] = <<-MESSAGE
          You will receive all e-mail communications from Flair Event Staffing.
        MESSAGE
        redirect_to '/staff'
      end
    end
  end

  def induction_popup
    current_user.update(interview_induction: true)
    if params[:to] == 'events'
      redirect_to '/staff/events'
    else
      redirect_to '/staff#interview'
    end
  end

  private

  def send_interview_email(interview)
    send_mail(StaffMailer.auto_email_for_interview_booking_time(current_user, interview))
  end

  def update_applicant_status(prospect, n_active_events)
    if prospect.applicant?
      status =
        if n_active_events > 0
          'ACTIVE'
        else
          if prospect.has_mandatory_profile_information?
            'LIVE'
          else
            'HOLDING'
          end
        end
      if prospect.applicant_status != status
        prospect.applicant_status = status
        prospect.save!
      end
    else
      unless prospect.applicant_status == nil
        prospect.applicant_status = nil
        prospect.save!
      end
    end
  end

  def profile_complete?(prospect)
    prospect.has_personal_details? &&
    #prospect.has_contact_preferences? &&
    prospect.answered_mandatory_questions? &&
    prospect.has_photo? &&
    ((prospect.agreed_to_terms? && prospect.has_bank_details? && prospect.has_tax_choice? && prospect.id_submitted?) || prospect.applicant?)
  end

  def get_profile_badge_count(prospect)
    total = 0
    total +=1 unless prospect.has_personal_details?
    total +=1 unless prospect.answered_latest_mandatory_questions?
    # total +=1 unless prospect.has_contact_preferences?
    if !prospect.applicant?
      total +=1 unless prospect.agreed_to_terms?
      total +=1 unless prospect.has_bank_details?
      total +=1 unless prospect.has_tax_choice?
      total +=1 unless prospect.id_submitted?
    end
    total
  end

  def get_progress_percent(prospect, interview, required_training, n_events)
    weightings = []
    weightings << {complete: prospect.has_personal_details?, weight: 1}
    weightings << {complete: prospect.answered_whole_questions?, weight: 1}
    # weightings << {complete: prospect.has_contact_preferences?, weight: 1}
    weightings << {complete: prospect.has_photo?, weight: 1}
    if prospect.applicant?
      weightings << {complete: interview.present?, weight: 1}
    else
      weightings << {complete: prospect.agreed_to_terms?,  weight: 1}
      weightings << {complete: prospect.has_bank_details?, weight: 1}
      weightings << {complete: prospect.has_tax_choice?,     weight: 1}
      weightings << {complete: prospect.id_submitted?,     weight: 1}
      weightings << {complete: n_events > 0, weight: 1}
      #required_training.each do |tl|
      #  weightings << {complete: tl.complete?, weight: 1}
    end

    total = value = 0
    weightings.each do |weighting|
      value += weighting[:weight] if weighting[:complete]
      total += weighting[:weight]
    end
    (100*value.to_f/total.to_f/5).floor() * 5 #Round to nearest 5 percent (for progress indicator)
  end

  def get_flair_level(number_of_gigs)
    if number_of_gigs >= 16
      'Rock Star'
    elsif number_of_gigs >= 11
      'Expert'
    elsif number_of_gigs >= 4
      'Experienced'
    elsif number_of_gigs >= 1
      'Novice'
    else
      'Newbie'
    end
  end

  def digit_to_word(digit)
    %w(zero one two three four five six seven eight nine)[digit]
  end

  def get_interview_calendar(prospect, type)
    event_ids = GigRequest.where(prospect_id: prospect.id, gig_id: nil).pluck(:event_id).uniq
    # date_today = Date.today()
    current_date = Date.today
    if current_date.strftime("%A") === 'Saturday' || current_date.strftime("%A") === 'Sunday'
      start_of_current_week = current_date.at_beginning_of_week + 7
    else
      start_of_current_week = current_date.at_beginning_of_week
    end
    # Friday of this week
    first_friday_7pm = start_of_current_week + (5 - start_of_current_week.wday) + 19.hours
    if Time.now() < first_friday_7pm
      interview_blocks = InterviewBlock.order(:date).includes(:bulk_interview).joins(:bulk_interview).where('interview_blocks.date >= ? AND bulk_interviews.status IN (?) AND bulk_interviews.interview_type in (?) AND (bulk_interviews.target_region_id IS NULL OR bulk_interviews.target_region_id = ?)' , start_of_current_week, ['OPEN', 'HAPPENING'], ['ONLINE','IN_PERSON'], prospect.region_id).all
    else
      interview_blocks = InterviewBlock.order(:date).includes(:bulk_interview).joins(:bulk_interview).where('interview_blocks.date >= ? AND bulk_interviews.status IN (?) AND bulk_interviews.interview_type in (?) AND (bulk_interviews.target_region_id IS NULL OR bulk_interviews.target_region_id = ?)' , start_of_current_week + 7, ['OPEN', 'HAPPENING'], ['ONLINE','IN_PERSON'], prospect.region_id).all
    end
    interview_blocks = interview_blocks.select { |ib|
      bulk_interview_events = BulkInterviewEvent.where(bulk_interview: ib.bulk_interview)
      if bulk_interview_events.exists?
        # Check if this bulk interview is associated with this person's event
        bulk_interview_events.where(event_id: event_ids).exists?
      else
        # No events associated with this bulk interview
        true
      end
    }
    # interview_slots = InterviewSlot.includes(:interview_block).where(interview_block_id: interview_blocks.map(&:id)).sort_by {|is| [is.date, is.time_start]}

    # interview = Interview.where(prospect_id: prospect.id).first
    # interview_calendar = {}
    # interview_slots.each do |is|
    #   cutoff = Time.now.in_time_zone('Europe/London') + 15.minutes
    #   if (is.date != Time.now.in_time_zone('Europe/London').utc.to_date) || (baseline_time_for_comparison(cutoff) < baseline_time_for_comparison(is.time_end))
    #     interview_calendar[get_week_of_date(is.date)] ||= {}
    #     week = interview_calendar[get_week_of_date(is.date)]
    #     week[is.date] ||= {}
    #     week[is.date][is.time_start] ||= []
    #     week[is.date][is.time_start] << {id: is.id, status: get_interview_slot_status(is, interview), type: is.type}
    #     # week[:earliest_time] = [week[:earliest_time] || is.time_start, is.time_start].min
    #     # week[:latest_time]   = [week[:latest_time]   || is.time_start, is.time_start].max
    #   end
    # end
    interview_calendar = {first: [], second: []}
    interview_blocks.each do |ib|
      # debugger
      first_friday = start_of_current_week + (5 - start_of_current_week.wday)
      if Time.now() < first_friday_7pm
        if ib.date <= first_friday
          interview_calendar[:first] << ib
        elsif interview_calendar[:second].count < 5
          interview_calendar[:second] << ib
        end
      else
        # debugger
        sceond_friday = start_of_current_week + (5 - start_of_current_week.wday) + 7.days
        if ib.date != first_friday
          if ib.date <= sceond_friday
            interview_calendar[:first] << ib
          elsif interview_calendar[:second].count < 5
            interview_calendar[:second] << ib
          end
        end
      end
    end

    interview_calendar
  end

  def baseline_time_for_comparison(time)
    Time.new(2000, 1, 1, time.hour, time.min, time.sec, '+00:00')
  end

  def get_week_of_date(date)
    date - monday_based_wday(date)
  end

  def monday_based_wday(date)
    offset = date.wday
    offset = 7 if offset == 0 #Sunday is usually 0
    offset -= 1 #but we want Monday to be 0
  end

  def get_interview_slot_status(slot, interview = nil)
    if slot.id == interview.try(:interview_slot_id)
      'SIGNED-UP'
    elsif slot.interviews_count >= slot.max_applicants
      'FULL'
    else
      'OPEN'
    end
  end

  def get_id_view(prospect)
    if request.variant.present?
      if @prospect.nationality.nil?
        'v2/mobile/staff/profile_upload_id_nationality'
      elsif @prospect.nationality.uk?
        'v2/mobile/staff/profile_upload_id_uk_type'
      elsif @prospect.nationality.ireland?
        'v2/mobile/staff/profile_upload_id_roi_passport'
      else
        'v2/mobile/staff/profile_upload_id_others'
      end
    else
      if @prospect.nationality.nil?
        'v2/staff/profile_upload_id_nationality'
      elsif @prospect.nationality.uk?
        'v2/staff/profile_upload_id_uk_type'
      elsif @prospect.nationality.ireland?
        'v2/staff/profile_upload_id_roi_passport'
      else
        'v2/staff/profile_upload_id_others'
      end
    end
  end

  def get_uk_id_view(prospect)
    if request.variant.present?
      @prospect.id_type == 'BC+NI' ? 'v2/mobile/staff/profile_upload_id_uk_birth_certificate' : 'v2/mobile/staff/profile_upload_id_uk_passport' #default
    else
      @prospect.id_type == 'BC+NI' ? 'v2/staff/profile_upload_id_uk_birth_certificate' : 'v2/staff/profile_upload_id_uk_passport' #default
    end
  end

  def handle_scanned_id_uploads(id_no_document, id_type, uploaded_hash)
    @prospect = current_user
    if params[:id_expiry].present?
      if params[:id_expiry].as_json.length == 3
        if params[:id_expiry][:day].present? && params[:id_expiry][:month].present? && params[:id_expiry][:year].present?
          if params[:id_no].try(:strip).present? && (id_type != 'Work/Residency Visa' || params[:share_code].try(:strip).present?)
            current_user.id_number = params[:id_no].strip
            current_user.id_expiry = hash_to_date(params[:id_expiry]) if params[:id_expiry].present?
            current_user.id_type = id_type
            current_user.visa_number = params[:visa_no].strip if params[:visa_no].try(:strip).present?

            if id_type == 'Work/Residency Visa'
              if params[:visa_indefinite].blank? && hash_to_date(params[:visa_expiry]).blank? 
                flash[:error] = 'You must fill in your visa expiry'
                return redirect_to '/staff#application-identification'
              end
              current_user.visa_indefinite = params[:visa_indefinite].present?
              current_user.visa_expiry = hash_to_date(params[:visa_expiry])
              # current_user.visa_issue_date = hash_to_date(params[:visa_issue_date])
            else
              current_user.visa_expiry = nil
            end
          else
            flash[:error] = "You must fill in your #{id_no_document} number."
            redirect_to '/staff#application-identification'
            return
          end
        else
          flash[:error] = "You must fill in complete Id Expiry Date."
          redirect_to '/staff#application-identification'
          return
        end
      else
        if params[:id_expiry].length == 10
          if params[:id_no].try(:strip).present? && (id_type != 'Work/Residency Visa' || params[:share_code].try(:strip).present?)
            current_user.id_number = params[:id_no].strip
            # current_user.id_expiry = hash_to_date(params[:id_expiry]) if params[:id_expiry].present?
            if request.variant.present?
              current_user.id_expiry = params[:id_expiry]
            end
            current_user.id_type = id_type
            current_user.visa_number = params[:visa_no].strip if params[:visa_no].try(:strip).present?

            if id_type == 'Work/Residency Visa'
              if params[:visa_indefinite].blank? && params[:visa_expiry].blank?
                flash[:error] = 'You must fill in your visa expiry'
                return redirect_to '/staff#application-identification'
              end
              current_user.visa_indefinite = params[:visa_indefinite].present?
              if current_user.visa_indefinite == false
                if request.variant.present?
                  current_user.visa_expiry = params[:visa_expiry]
                end
              end
              # if request.variant.present?
                # current_user.visa_issue_date = params[:visa_issue_date]
              # end
              # current_user.visa_expiry = hash_to_date(params[:visa_expiry])
              # current_user.visa_issue_date = hash_to_date(params[:visa_issue_date])
            else
              current_user.visa_expiry = nil
            end
          else
            flash[:error] = "You must fill in your #{id_no_document} number."
            redirect_to '/staff#application-identification'
            return
          end
        else
          flash[:error] = "You must fill in complete Id Expiry Date."
          redirect_to '/staff#application-identification'
          return
        end
      end
    else
      if params[:id_no].try(:strip).present? && (id_type != 'Work/Residency Visa' || params[:visa_no].try(:strip).present?)
        current_user.id_number = params[:id_no].strip
        current_user.id_expiry = hash_to_date(params[:id_expiry]) if params[:id_expiry].present?
        current_user.id_type = id_type
        current_user.visa_number = params[:visa_no].strip if params[:visa_no].try(:strip).present?

        if id_type == 'Work/Residency Visa'
          current_user.visa_indefinite = params[:visa_indefinite].present?
          current_user.visa_expiry = hash_to_date(params[:visa_expiry])
          current_user.visa_issue_date = hash_to_date(params[:visa_issue_date])
        else
          current_user.visa_expiry = nil
        end
      else
        flash[:error] = "You must fill in your #{id_no_document} number."
        redirect_to '/staff#application-identification'
        return
      end
    end

    if current_user.id_type == 'UK Passport' || current_user.id_type == "EU Passport"
      if request.variant.present?
        if params[:id_expiry]
          current_user.id_expiry = params[:id_expiry]
        end
      end
      current_user.validate_id_expiry_present

      if current_user.errors.empty?
        current_user.save
      else
        flash[:error] = current_user.errors.full_messages.to_sentence
        redirect_to '/staff#application-identification' and return
      end
    end

    directory = File.join(Flair::Application.config.shared_dir, 'scanned_ids')
    lrg_dir   = File.join(Flair::Application.config.shared_dir, 'scanned_ids_large')

    if uploaded_hash.values.all?
      current_user.id_submitted_date = Date.today()
      current_user.save!
      current_user.scanned_ids.destroy_all

      uploaded_hash.each do |name,uploaded|
        file_name = "#{current_user.id}_#{name}"
        result = handle_general_upload(uploaded, directory, file_name, {width: 400, height: 400})
        unless result == :ok
          handle_failed_image_upload(result, '/staff#application-identification')
          return
        end
        file_format = uploaded.original_filename.split('.').last
        if file_format != 'pdf'
          uploaded.rewind
          result = handle_general_upload(uploaded, lrg_dir, file_name, {width: 800, height: 800})
          unless result == :ok
            handle_failed_image_upload(result, '/staff#application-identification')
            return
          end
        end
      end

      uploaded_hash.each do |name,uploaded|
        current_user.scanned_ids.create(photo: "#{current_user.id}_#{name}.#{output_file_format(File.extname(uploaded.original_filename))}")
      end
    else
      flash[:error] = "Please select all the required ID scans for upload, and fill in your #{id_no_document} number."
    end

    redirect_to '/staff#application-identification'
  end

  def handle_failed_image_upload(reason, redirect_url)
    case reason
    when :thumbnail_failed
      flash[:error] = <<-MESSAGE
        A server error occurred while processing your photo. The file may be corrupted.
        If this happens every time you try to upload this file, please contact us at 0161 241 2441 or work@flairevents.co.uk for help.
      MESSAGE
    when :not_enough_space
      flash[:error] = "Sorry, there is not enough free space on the server's hard drive."
    when :too_large
      flash[:error] = "Photo files cannot be larger than 20 megabytes."
    when :unknown_image_type
      flash[:error] = "Photos must be .jpg, .jpeg, .gif, or .png files."
    else
      flash[:error] = "Unable to save photo. Please contact us at 0161 241 2441 or work@flairevents.co.uk for help."
    end
    flash.keep # required when redirecting from a POST request
    
    respond_to do |format|
      format.html { redirect_to redirect_url }
      format.json do 
        error = flash[:error]
        flash[:error] = nil
        
        render json: { error: error }, status: 400 
      end
    end
    
  end

  def hash_to_date(hash)
    if hash[:year].present? && hash[:month].present? && hash[:day].present?
      year = hash[:year].to_i
      month = hash[:month].to_i
      day = [hash[:day].to_i, Time.days_in_month(month, year)].min
      Date.civil(year, month, day)
    end
  end

  def destroy_gig(gig)
    #Only destroy the gig if there are no associated tax weeks
    if PayWeek.where(prospect_id: gig.prospect_id, event_id: gig.event_id).empty?
      gig.destroy
    else
      #If there are associated tax weeks, then just make the gig inactive
      gig.status = 'Inactive'
      gig.save!
    end
  end

  def distance_between_points(loc1, loc2)
    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[0]-loc1[0]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[1]-loc1[1]) * rad_per_deg

    lat1_rad, lon1_rad = loc1.map {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = loc2.map {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    rm * c # Delta in meters
  end

  def get_coords_from_postcode(post_code)
    post_area = PostArea.where(subcode: post_code.split(' ')[0]).first
    [post_area.latitude, post_area.longitude]
  end

  def distance_between_post_codes_in_miles(post_code1, post_code2)
    if valid_post_code(post_code1) && valid_post_code(post_code2)
      (distance_between_points(get_coords_from_postcode(post_code1), get_coords_from_postcode(post_code2)))/1000*0.62137.round
    else
      0
    end
  end

  def valid_post_code(post_code)
    post_code && PostArea.where(subcode: post_code.split(' ')[0]).exists?
  end

  def get_prospects_event_status(prospect, event)
    gig = Gig.where(event_id: event.id, prospect_id: prospect.id).first
    confirmed = gig && gig.gig_tax_weeks.where(confirmed: true).exists?
    if gig && event.status == 'CLOSED'
      "Completed"
    # elsif gig && confirmed && gig.event.date_start <= Date.today() && gig.status == 'Active'
    elsif gig && event.date_callback_due == nil
      "In Progress"
    # elsif gig && confirmed
    elsif gig && event.date_callback_due && confirmed
      "Confirmed"
    # elsif gig
    elsif gig && event.date_callback_due
      "Signed Up"
    elsif GigRequest.where(event_id: event.id, prospect_id: prospect.id).exists?
      "Pending"
    else
      "Available"
    end
  end

  def events_to_show(category, region, keyword = nil)

    query = ''
    if category
      category_names =   category == 'Events' ? 'Events,Concert' : category
      category_ids = EventCategory.where(name: category_names.split(',').map(&:titleize)).ids
      query << "category_id IN (#{category_ids.join(',')})"
    end

    ## old region code
    # if region
    #   events = Event.includes(:jobs, :region).visible.not_finished.where(region_id: Region.find_by_name(region).id, show_in_ongoing: ongoing, show_in_public: true).where(query)
    # else
    #   events = Event.includes(:jobs, :region).visible.not_finished.where(show_in_ongoing: ongoing, show_in_public: true).where(query)
    # end
    if region
      region2 = region.delete(' ')
      if query.present?
        query << " AND "
      end
      if region != region2
        query << "(lower(location) LIKE '%#{region.downcase}%' OR lower(regions.name) LIKE '%#{region.downcase}%') OR (lower(location) LIKE '%#{region2.downcase}%' OR lower(regions.name) LIKE '%#{region2.downcase}%')"
      else
        query << "(lower(location) LIKE '%#{region.downcase}%' OR lower(regions.name) LIKE '%#{region.downcase}%')"
      end
    end

    if keyword
      if query.present?
        query << " AND "
      end
      query << "(lower(events.display_name) LIKE '%#{keyword.downcase}%' OR lower(events.jobs_description) LIKE '%#{keyword.downcase}%' OR lower(jobs.name) LIKE '%#{keyword.downcase}%' OR lower(jobs.public_name) LIKE '%#{keyword.downcase}%')"
    end

    events = Event.includes(:jobs, :region).visible.not_finished.where(show_in_public: true, jobs: { include_in_description: true }).where(query).references(:jobs, :region).order(:public_date_start)

    if events.empty?
      empty_message = "No"
      empty_message << " "+category if category.present?
      # empty_message << ' Ongoing' if ongoing.present?
      empty_message << " events"
      empty_message << " in #{region}" if region.present?
      empty_message << "."
    end

    {events: events, empty_message: empty_message}
  end

  def putstar(message)
    5.times { puts("**************************") }
    puts(message)
    5.times { puts("**************************") }
  end

  def prospect_params(params)
    params.permit(:interview, :first_name, :last_name, :date_of_birth, :gender, :country, :nationality, :address,
                  :post_code, :email, :nationality_id, :mobile_no, :home_no, :ni_number, :address2, :city, :date_end,
                  :date_inactive, :emergency_name, :emergency_no, :prefers_in_person, :prefers_phone,  :prefers_skype,
                  :prefers_facetime, :preferred_skype, :preferred_facetime, :preferred_phone, :prefers_morning,
                  :prefers_afternoon, :prefers_early_evening, :prefers_midweek, :prefers_weekend, :tax_choice, :id_type,
                  :student_loan, :id_number, :visa_number, :bank_sort_code, :visa_expiry, :bank_account_no,
                  :bank_account_name, :good_sport, :good_bar, :good_promo, :bar_license_issued_by, :good_hospitality,
                  :good_management, :send_marketing_email, :city_of_study)
  end

  def authenticate_user!
    if current_user.is_a?(Officer)
      logout_account
    end

    unless current_user
      if request.xhr?
        render json: { logged_in: false}
      else
        redirect_to '/login'
      end
    end
  end

  def authenticate_user_polling!
    unless current_user
      if request.xhr?
        render json: { logged_in: false}
      else
        redirect_to '/login'
      end
    end
  end

  def check_if_confirmed
    if params[:token].present?
      @account = Account.find_by(one_time_token: params[:token])
      if @account.present?
        @account.confirmed_email = true
        @account.save
      end

      # if current_user.present?
      #   if current_user.account.one_time_token == params[:token]
      #     current_user.account.confirmed_email = true
      #   end
      # end
    end
    if current_user.account.confirmed_email == false
      flash[:error] = "Confirm your email first to proceed"
      return redirect_to '/onboard'
    end
  end

  def check_if_user_done_profile
    if !current_user.has_personal_details?
      flash[:error] = "Please fill up your profile details to proceed to job board."
      flash[:redirect] = "profile"
      return redirect_to '/staff'
    end
  end

end
