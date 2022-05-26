require 'active_support'
require 'tempfile'
require 'file_uploads'
require 'brightpay'
require 'models/export'
require 'user_info'
require 'fastimage'
require 'write_xlsx'
require 'rinku'
require 'icalendar'
require 'spicy-proton'

class OfficeController < ApplicationController
  include FileUploads
  include ActionView::Helpers::SanitizeHelper
  include Brightpay
  include Models::Export

  layout 'office'
  before_action :set_prospect, only: [:send_confirmation_email]
  # force_ssl is configured in config/evironments/*.rb
  # For staging however, this is too strict and browsers will prevent access to the staging site if the certificate is
  #   invalid, so we set it here instead
  force_ssl if Rails.env.staging?

  only_accessible_to_officers except: [:login, :relogin]
  only_accessible_to_managers only:   [:create_officer, :update_officer, :delete_officer,
    :create_content, :update_content, :delete_content]

  ##### Make current_user accessible to models (specifically OfficeZoneSync)
  before_action :set_user
  def set_user
    UserInfo.current_user = current_user
    UserInfo.controller_name = controller_name
  end

  # Report downloads are done using a jQuery plugin which (naturally) doesn't send the CSRF
  #   protection token which Rails expects
  # Our own AJAX code also uses POST requests for certain things, without sending CSRF
  #   protection token
  skip_before_action :verify_authenticity_token

  # NAME:        index
  # DESCRIPTION: The main page (the parent)
  #              Essentially loads the HTML/JS "application" which is the Office Zone
  #              After loading, the Office Zone pulls all the data it needs using #data, below
  #              After that all page transitions are done either by rendering client-side,
  #                or by retrieving HTML using an AJAX call
  def index
    @events = Event.current_year_number_of_events
    @prospects = Prospect.current_year_number_of_employees
    @jobs = Assignment.current_year_number_of_assignments
  end

  # NAME:        data
  # DESCRIPTION: Retrieve all data used by Office View "application" as JSON
  #              If the client has pulled data already, it will give us a timestamp
  #                and we will only send back data newer than that timestamp
  def data
    timestamp = Time.now.to_i # UNIX timestamp -- "this data is good as of..."
    last_time = params[:last].present? && Time.at(params[:last].to_i)
    deletions = if last_time then Deletion.where('updated_at >= ?', last_time).group_by(&:table) else [] end

    self.response_body = Enumerator.new do |resp|
      resp << "{\"tables\":"
      resp << export_all_data_to_hash(last_time, current_user.manager?) << ','
      resp << "\"todos\":     #{get_todos(last_time).to_json},"
      resp << "\"deleted\":   {#{deletions.map { |table,records| "\"#{table}\": [#{records.map(&:record_id).join(',')}]" }.join(',')}},"
      resp << "\"timestamp\": #{timestamp}}"
    end
  end

# NAME:        get_evemt_manager
# DESCRIPTION: Get event manager id in JSON
  def get_event_manager
    event = Event.find params[:id]
    return render json: {officer_id: event.office_manager_id}
  end

# NAME:        create_prospect
# DESCRIPTION: Validate data for new Prospect, either save it to DB/return validation errors
#              If data is good, return JSON for updated record (used to update client-side cache)
  def create_prospect
    attrs = params[:prospect]
    attrs[:post_code].strip! if attrs[:post_code]

    prospect = Prospect.new
    [:date_of_birth].each { |k| attrs[k] = attrs[k].to_date if attrs[k].present? }
    prospect.assign_attributes(prospect_params(attrs).reject { |k,v| v.blank? })

    if prospect.validate_mandatory_office_fields

      if params[:prospect][:has_c19_test] == "1"
        prospect.c19_tt_at = Time.now
      end

      if prospect.save
        account = Account.new(user: prospect)
        account.generate_one_time_token!
        account.save
      end
    else
      message = prospect.errors.full_messages.to_sentence
    end
    render json: OfficeZoneSync.get_synced_response({message: message})
  end

  def main_work_area_events
    puts "====================================================="
    puts params

    location_id = params[:location_id].to_i
    event = Location.find(location_id).event

    tax_week_id = TaxWeek.find(params[:tax_week_id]) ? TaxWeek.find(params[:tax_week_id]).id : nil

    prospects = event.gigs.includes(:prospect).map{|gig|
      gig.location_id == location_id ? gig.prospect : []
    }.flatten.uniq

    table = ""

    job_ids = event.gigs.pluck("job_id").uniq
    jobs = Job.find(job_ids).map{|job| [job.name, job.id]}
    areas = Location.where(event_id: event.id).map{|location| [location.name, location.id]}

    prospects.each_with_index do |prospect, index|
      if index%2 == 0
        row_type = "even"
      else
        row_type = "odd"
      end

      gig = prospect.gigs.where(event_id: event.id).first

      avg_rating = prospect.average_rating != nil ? prospect.average_rating : 0

      # Jobs
        if gig.location_id == nil
          main_job = jobs
        else
          jobs_ids = event.gigs.where(location_id: gig.location_id).pluck("job_id").uniq
          main_job = Job.find(job_ids).map{|job| [job.name, job.id]}
        end

        main_job_options = ""

        main_job.each do |job|
          puts job[1]
          puts gig.job_id
          puts "====================================================="
          main_job_options += job[1].to_i == gig.job_id ? "<option value=#{job[1]} selected='selected'>#{job[0]}</option>" : "<option value=#{job[1]}>#{job[0]}</option>"
        end

      # Locations
        if gig.job_id == nil
          main_area = areas
        else
          location_ids = Assignment.where(event_id: event.id, job_id: gig.job_id).map{|assignment| assignment.location_id}.flatten.uniq
          main_area = Location.find(location_ids).map{|location| [location.name, location.id]}
        end

        main_area_options = ""

        main_area.each do |location|
          main_area_options += location[1].to_i == gig.location_id ? "<option value=#{location[1]} selected='selected'>#{location[0]}</option>" : "<option value=#{location[1]}>#{location[0]}</option>"
        end

      # Assignments
        raw_assignments = prospect.gigs.where(event_id: event.id).first.assignments.includes([:shift, :job]).map{|assignment| assignment.shift.tax_week_id == 402 ? assignment : []}.flatten.uniq

        assignments = raw_assignments.collect do |assignment|
          ["#{gig.location_id ? gig.location_id == location_id ? '' : assignment.location.name + ":" : assignment.location.name + ":"}#{assignment.shift.date.strftime("%a %e #{assignment.shift.date.day.ordinalize}")} (#{assignment.shift.time_start.strftime('%R')}-#{assignment.shift.time_end.strftime('%R')} #{assignment.staff_count}✓ #{assignment.staff_count}/#{assignment.staff_needed}", assignment.id, assignment.staff_count, assignment.staff_needed]
        end

        first_select = ""
        assignments.each do |assignment|
          first_select += "
            <option value=#{assignment[1]} selected='selected' class='assignment-#{assignment[2] < assignment[3] ? 'open' : 'full'}'>#{assignment[0]}</option>
          "
        end

        second_select = ""
        raw_assignments.each_with_index do |assignment, index|
          second_select += "
            <li class='select2-selection__choice day-of-week-#{assignment.shift.date.strftime('%A').downcase}' title='#{assignments[index][0]}'>
              <span class='select2-selection__choice__remove' role='presentation'>×</span>
              #{assignments[index][0]}
            </li>
          "
        end

      # Tags
        raw_tags = prospect.gigs.where(event_id: event.id).first.tags.map{|tag| [tag.name, tag.id]}
        tags = ""
        ul_tags = ""

        raw_tags.each do |tag|
          tags += "
            <option value=#{tag[1]}>#{tag[0]}</option>
          "
        end

        raw_tags.each do |tag|
          ul_tags += "
            <li class='select2-selection__choice' title='#{tag[0]}'>
              <span class='select2-selection__choice__remove' role='presentation'>×</span>
              #{tag[0]}
            </li>
          "
        end

      # Distance
        distance = 0

      # ID
        status_id = prospect.status == 'EXTERNAL' ? '' : "\u2714"

      # tax_choice
        tax_choice = prospect.status == 'EXTERNAL' ? '' : "\u2714"

      # email
        template = prospect.gigs.where(event_id: event.id).first.gig_tax_weeks.where(tax_week_id: 402).first

        if template
          template = template.assignment_email_template
          if template
            if template.name
              case prospect.gigs.where(event_id: event.id).first.gig_tax_weeks.where(tax_week_id: 402).first.assignment_email_type
              when 'ShiftOffer'
                type = 'Shift Offer'
              when 'CallToConfirm'
                type = 'Call'
              when 'EmailToConfirm'
                type = 'Email'
              when 'BookedOffer'
                type = 'Booked Offer'
              else
                type = prospect.gigs.where(event_id: event.id).first.gig_tax_weeks.where(tax_week_id: 402).first.assignment_email_type
              end

              email = template.name == 'Default' ? type : type + ":" + template.name
            else
              email = ''
            end
          else
            email = ''
          end
        else
          email = ''
        end
      # TD 4 need confirmed (check gigs-view.coffee) to know if its checked or not
      # TD 6 need name classes (check gigs-view.coffee), I used the ELSE codes

      table += "
        <tr class='body-row tr-#{row_type}' data-index=#{index}>
          <td class='td td-string' style='display: none;'>
            <input type='text' name='[gigs][#{gig.id}][tax_week_id]' value='#{tax_week_id}'>
          </td>
          <td class='td td-string'>
            <input type='checkbox' class='fire-checkbox never-dirty' name='fire[]' value='#{gig.id}'>
          </td>
          <td class='td td-string'>
            <input type='checkbox' name='[gigs][#{gig.id}][miscellaneous_boolean]' #{gig.miscellaneous_boolean ? "checked='checked'" : ""}>
          </td>
          <td class='td td-string'>
            <input type='checkbox' name='[gigs][#{gig.id}][confirmed]' checked='checked' #{tax_week_id ? '' : "disabled='disabled'"} >
          </td>
          <td class='td td-string'>
            <input type='checkbox' name='[gigs][#{gig.id}][published]' #{gig.published ? "checked='checked'" : ''} readonly='' onclick='return false;'>
          </td>
          <td class='td td-string'>
            <img src='/prospect_photo/#{prospect.id}?force_refresh=#{rand()}' class='team_photo' ><b class='gig-view-name-size'>#{prospect.last_name}, #{prospect.first_name}</b><br> <small  style='float: left;'> R: #{avg_rating}</small>" + "<small style='margin-left: 10px; float: left;'> #E:#{prospect.gigs_count} </small> #{prospect.flag_photo}
          </td>
          <td class='td td-string'>
            <select class='jobs-dropdown form-control' name='[gigs][#{gig.id}][job_id]'>
              <option value=''></option>
              #{main_job_options}
            </select>
          </td>
          <td class='td td-string'>
            <select class='locations-dropdown form-control' name='[gigs][#{gig.id}][location_id]'>
              <option value=""></option>
              #{main_area_options}
            </selected>
          </td>
          <td class='td td-string' style='display: none;'>
            <select class='all-filtered-assignment-ids form-control' name='[gigs][#{gig.id}][all_filtered_assignment_ids][]' multiple>
              #{first_select}
            </select>
          </td>
          <td class='td td-string'>
            <select class='assignments-dropdown change-on-set-val select2-hidden-accessible' name='[gigs][#{gig.id}][assignment_ids][]' multiple tabindex='-1' aria-hidden='true'>
              #{first_select}
            </select>
            <span class='select2 select2-container select2-container--default select2-container--focus' dir='ltr' style='width: 100%;'>
              <span class='selection'>
                <span class='select2-selection select2-selection--multiple assignments-dropdown-select2' role='combobox' aria-haspopup='true' aria-expanded='false' tabindex='-1'>
                  <ul class='select2-selection__rendered'>
                    #{second_select}
                  </ul>
                </span
              </span>
              <span class='dropdown-wrapper' aria-hidden='true'></span>
            </span>
          </td>
          <td class='td td-string'>
            <select class='tags-dropdown change-on-set-val select2-hidden-accessible' name='[gigs][212665][tag_ids][]' multiple tabindex='-1' aria-hidden='true'>
              <option value=''></option>
              #{tags}
            </select>
            <span class='select2 select2-container select2-container--default tags-dropdown-container' dir='ltr' style='width: 100%;'>
              <span class='selection'>
                <span class='select2-selection select2-selection--multiple' role='combobox' aria-haspopup='true' aria-expanded='false' tabindex='-1'>
                  <ul class='select2-selection__rendered'>
                    #{ul_tags}
                    <li class='select2-search select2-search--inline'>
                      <input class='select2-search__field' type='search' tabindex='0' autocomplete='off' autocorrect='off' autocapitalize='none' spellcheck='false' role='textbox' aria-autocomplete='list' placeholder='' style='width: 0.75em;'>
                    </li>
                  </ul>
                </span>
              </span>
              <span class='dropdown-wrapper' aria-hidden='true'></span>
            </span>
          </td>
          <td class='td td-string'>
            <input type='text' class=' form-control' name='[gigs][#{gig.id}][notes]' value='#{gig.notes}'>
          </td>
          <td class='td td-string'>
            #{email}
          </td>
          <td class='td td-boolean'>
            #{tax_choice}
          </td>
          <td class='td td-boolean'>
            #{status_id}
          </td>
          <td class='td td-string'>
            <div style='width: fit-content; margin: auto;'>#{distance}</div>
          </td>
          <td class='td td-string'>
            <select class='status-dropdown form-control' name='gigs][#{gig.id}][status]'>
              <option value='Active' #{gig.status == "Active" ? "selected='selected'" : ''}>Y</option>
              <option value='Inactive' #{gig.status == "Inactive" ? "selected='selected'" : ''}>N</option>
            </select>
          </td>
          <td class='td td-number'>
            #{prospect.age}
          </td>
        </tr>
      "
    end

    render json: table
  end

  def update_tax_year
    old_tax_year = TaxYear.find(9)

    old_tax_year.update_tax_year_2021

    new_tax_year = TaxYear.find(9)

    render json: {old: old_tax_year, new: new_tax_year}
  end

# NAME:        update_prospect
# DESCRIPTION: Validate changed data for existing Prospect, either save it to DB/return validation errors
#              If data is good, return JSON for updated record (used to update client-side cache)

  def update_prospect
    params[:prospects] = {}
    params[:prospects][params[:id]] = params[:prospect]
    if Prospect.exists? params[:id]
      update_prospects
    else
      render json: {status: "ok", message: "Prospect was previously deleted.", deleted: {prospects: params[:id]}}
    end
  end

  def send_confirmation_email
     send_mail(PublicMailer.remind_to_confirm_email_5(@prospect, @prospect.account))
     render json: OfficeZoneSync.get_synced_response({message: "A new verification email has been sent! \n\nTime to say hi and start to build rapport with the candidate. Encourage the ‘Joining Flair People’ flow."})
  end

  def set_prospect
    @prospect = Prospect.find_by(id: params[:id])
    if @prospect.blank?
      render json: {status: "error", message: "Invalid prospect id"}
    end
  end

  def update_prospects
    mails = []

    if params[:prospects]
      prospects = Prospect.find(params[:prospects].keys)

      prospects.each do |prospect|
        check_c19_test = prospect.has_c19_test
        puts check_c19_test
        attrs = params[:prospects][prospect.id.to_s].except(:questionnaire)
        [:date_of_birth, :visa_expiry].each { |k| attrs[k] = attrs[k].to_date if attrs[k].present? }
        if attrs[:good_promo].present?
          attrs[:left_voice_message] ||= prospect.left_voice_message
        else
          attrs[:left_voice_message] ||= false
        end
        attrs.each { |k,v| attrs[k] = nil if v == "" }
        attrs[:post_code].strip! if attrs[:post_code]
        if attrs[:id_type].present? && attrs[:id_type] != 'Work/Residency Visa' && attrs[:id_type] != 'Pass Visa'
          attrs[:visa_expiry] = nil       if prospect.visa_expiry
          attrs[:visa_issue_date] = nil   if prospect.visa_issue_date
          attrs[:visa_indefinite] = false if prospect.visa_indefinite
        end

        attrs[:share_code] = attrs[:share_code].upcase if attrs[:share_code]

        isCharacterChanged = false
        if attrs[:big_teams] == "Yes"
          attrs[:prospect_character] = "Big/"
          isCharacterChanged = true
        end
        if attrs[:all_teams] == "Yes"
          attrs[:prospect_character] = "#{attrs[:prospect_character]}All/"
          isCharacterChanged = true
        end
        if attrs[:bespoke] == "Yes"
          attrs[:prospect_character] = "#{attrs[:prospect_character]}Bes/"
          isCharacterChanged = true
        end
        if isCharacterChanged == true
          prospect_character = attrs[:prospect_character]
          attrs[:prospect_character] = prospect_character[0, prospect_character.length - 1]
        else
          attrs[:prospect_character] = nil
        end

        is_applicant = prospect.applicant?
        prospect_deactivated = attrs[:status] == 'DEACTIVATED' && prospect.status != 'DEACTIVATED'
        prospect_hired = attrs[:status] == 'EMPLOYEE' && prospect.status == 'APPLICANT'
        prospect_ignored = attrs[:status] == 'IGNORED' && prospect.status != 'IGNORED'

        average_rating = 0

        if attrs[:flair_image] != nil
          average_rating += attrs[:flair_image].to_f
        end

        if attrs[:experienced] != nil
          average_rating += attrs[:experienced].to_f
        end

        if attrs[:chatty] != nil
          average_rating += attrs[:chatty].to_f
        end

        if attrs[:confident] != nil
          average_rating += attrs[:confident].to_f
        end

        if attrs[:language] != nil
          average_rating += attrs[:language].to_f
        end

        # attrs[:rating] = average_rating

        attrs[:rating] = params[:prospect][:rating] if params[:prospect] && params[:prospect][:rating]&.present?

        prospect.assign_attributes(prospect_params(attrs))

        if questionnaire = prospect.questionnaire
          if params[:prospects][prospect.id.to_s][:questionnaire].present?
            questionnaire_params = params[:prospects][prospect.id.to_s][:questionnaire]

            questionnaire_params[:week_days_work] ||= false
            questionnaire_params[:weekends_work] ||= false
            questionnaire_params[:day_shifts_work] ||= false
            questionnaire_params[:evening_shifts_work] ||= false

            questionnaire_params[:contact_via_text] ||= false
            questionnaire_params[:contact_via_whatsapp] ||= false

            questionnaire_params[:dbs_qualification] ||= false
            questionnaire_params[:food_health_level_two_qualification] ||= false

            questionnaire_params[:bar_management_experience] ||= false
            questionnaire_params[:staff_leadership_experience] ||= false
            questionnaire_params[:festival_event_bar_management_experience] ||= false
            questionnaire_params[:event_production_experience] ||= false
            # questionnaire_params[:city_of_study] ||= ''


            questionnaire.assign_attributes(questionnaire_params(questionnaire_params))
            questionnaire.has_bar_and_hospitality = questionnaire_params[:has_bar_and_hospitality] == '' ? nil : questionnaire_params[:has_bar_and_hospitality]
            questionnaire.has_sport_and_outdoor = questionnaire_params[:has_sport_and_outdoor] == '' ? nil : questionnaire_params[:has_sport_and_outdoor]
            questionnaire.has_promotional_and_street_marketing = questionnaire_params[:has_promotional_and_street_marketing] == '' ? nil : questionnaire_params[:has_promotional_and_street_marketing]
            questionnaire.has_merchandise_and_retail = questionnaire_params[:has_merchandise_and_retail] == '' ? nil : questionnaire_params[:has_merchandise_and_retail]
            questionnaire.has_reception_and_office_admin = questionnaire_params[:has_reception_and_office_admin] == '' ? nil : questionnaire_params[:has_reception_and_office_admin]
            questionnaire.has_festivals_and_concerts = questionnaire_params[:has_festivals_and_concerts] == '' ? nil : questionnaire_params[:has_festivals_and_concerts]
            questionnaire.bar_management_experience = questionnaire_params[:bar_management_experience] == '' ? nil : questionnaire_params[:bar_management_experience]
            questionnaire.staff_leadership_experience = questionnaire_params[:staff_leadership_experience] == '' ? nil : questionnaire_params[:staff_leadership_experience]
            questionnaire.festival_event_bar_management_experience = questionnaire_params[:festival_event_bar_management_experience] == '' ? nil : questionnaire_params[:festival_event_bar_management_experience]
            questionnaire.event_production_experience = questionnaire_params[:event_production_experience] == '' ? nil : questionnaire_params[:event_production_experience]

            questionnaire.city_of_study = questionnaire_params[:city_of_study] == '' ? nil : questionnaire_params[:city_of_study]
            questionnaire.save

            prospect.bar_skill = questionnaire.has_bar
            prospect.hospitality_skill = questionnaire.has_bar_and_hospitality
            prospect.promo_skill = questionnaire.has_promotional_and_street_marketing
            prospect.retail_skill = questionnaire.has_merchandise_and_retail
            prospect.office_skill = questionnaire.has_reception_and_office_admin
            prospect.festival_skill = questionnaire.has_festivals_and_concerts
            prospect.sport_skill = questionnaire.has_sport_and_outdoor
            prospect.warehouse_skill = questionnaire.has_logistics

            prospect.staff_leader_skill = questionnaire.staff_leadership_experience.nil? ? false : questionnaire.staff_leadership_experience
            prospect.bar_manager_skill = questionnaire.bar_management_experience.nil? ? false : questionnaire.bar_management_experience

          end
        end

        # Check prospect c19_test
        if params[:prospect]
          if check_c19_test == false && params[:prospect][:has_c19_test] == "1"
            prospect.c19_tt_at = Time.now
          elsif check_c19_test == true && params[:prospect][:has_c19_test] == nil
            prospect.c19_tt_at = nil
          end

          if params[:prospect][:has_c19_test] != "1"
            prospect.has_c19_test = false
          end

          if params[:prospect][:is_clean] != "1"
            prospect.is_clean = false
          end

          if params[:prospect][:is_convicted] != "1"
            prospect.is_convicted = false
          end
        end

        if prospect_hired && !prospect.validate_mandatory_office_fields
          error_messages = prospect.errors.full_messages.to_sentence
          return render json: OfficeZoneSync.get_synced_response({message: error_messages})
        end

        if prospect.save
          if prospect_deactivated
            deactivate_account(prospect, is_applicant)
          end
          if prospect_hired
            hire_applicant(prospect)
            mails << StaffMailer.applicant_accepted(prospect)
          end
          if prospect_ignored
            ignore_prospect(prospect)
          end
        end
      end
    end

    if params[:interview_prospect_id]
      unless params[:interview_block_date].present? && params[:bulk_interview_id].present?
        Interview.find_by(prospect_id: params[:interview_prospect_id].to_i).destroy if Interview.find_by(prospect_id: params[:interview_prospect_id].to_i).present?
      end
      if params[:interview_block_date].present? && params[:bulk_interview_id].present?
        @interview_block = InterviewBlock.where(bulk_interview_id: params[:bulk_interview_id]).where(date: params[:interview_block_date])
        @interview_slot = InterviewSlot.where(interview_block_id: @interview_block.first.id).first
        @interview = Interview.find_by(prospect_id: params[:interview_prospect_id])
        if @interview
          @interview = @interview.update(prospect_id: params[:interview_prospect_id], interview_slot_id: @interview_slot.id, telephone_call_interview: true, video_call_interview: false, interview_block_id: @interview_block.first.id)
        else
          @interview = Interview.create!(prospect_id: params[:interview_prospect_id], interview_slot_id: @interview_slot.id, telephone_call_interview: true, video_call_interview: false, interview_block_id: @interview_block.first.id)
        end
      end
    end

    # Interviews are assigned in the applicants (prospect) table
    if params[:interviews]
      prospects = Prospect.find(params[:interviews].keys)
      interviews = []
      prospects.each do |prospect|
        if prospect.interview
          prev_interview = true
          prev_ibi = prospect.interview.interview_block.id
          prev_i_type = prospect.interview.time_type
        else
          prev_interview = false
          prev_ibi = nil
          prev_i_type = nil
        end
        attrs = params[:interviews][prospect.id.to_s]
        attrs.each { |k,v| attrs[k] = nil if v == "" }

        # interview_slot_id = attrs[:interview_slot_id]
        if attrs[:interview_slot_id]
          interview_block_raw = attrs[:interview_slot_id].split('.')
          interview_block_type = interview_block_raw[0]
          interview_block_id = interview_block_raw[1].to_i

          # check if interview is full
          interview_block = InterviewBlock.find(interview_block_id)
          interview_not_full = false
          case interview_block_type
          when 'MORNING'
            if interview_block.morning_interviews < interview_block.morning_applicants
              interview_not_full = true
            end
          when 'AFTERNOON'
            if interview_block.afternoon_interviews < interview_block.afternoon_applicants
              interview_not_full = true
            end
          when 'EVENING'
            if interview_block.evening_interviews < interview_block.evening_applicants
              interview_not_full = true
            end
          else
          end
        else
          interview_block_type = ""
          interview_block_id = nil
          interview_not_full = false
        end

        if prev_interview
          if interview_block_id && interview_not_full
            # minus first the prev interview from interview block
            interview_block = InterviewBlock.find(prev_ibi)
            case prev_i_type
            when 'MORNING'
              interview_block.morning_interviews = interview_block.morning_interviews - 1
              interview_block.save
            when 'AFTERNOON'
              interview_block.afternoon_interviews = interview_block.afternoon_interviews - 1
              interview_block.save
            when 'EVENING'
              interview_block.evening_interviews = interview_block.evening_interviews - 1
              interview_block.save
            else
            end

            # replace prev interview to new interview
            case interview_block_type
            when 'MORNING'
              interview_block.morning_interviews = interview_block.morning_interviews + 1
              interview_block.save
            when 'AFTERNOON'
              interview_block.afternoon_interviews = interview_block.afternoon_interviews + 1
              interview_block.save
            when 'EVENING'
              interview_block.evening_interviews = interview_block.evening_interviews + 1
              interview_block.save
            else
            end

            interview = Interview.new unless (interview = Interview.where(prospect_id: prospect.id).first)
            interview.interview_block_id = interview_block_id
            interview.interview_slot_id = interview_block.interview_slots.first.id
            interview.time_type = interview_block_type
            interview.prospect_id = prospect.id
            interview.save
          end
        else
          if interview_block_id && interview_not_full
            case interview_block_type
            when 'MORNING'
              interview_block.morning_interviews = interview_block.morning_interviews + 1
              interview_block.save
            when 'AFTERNOON'
              interview_block.afternoon_interviews = interview_block.afternoon_interviews + 1
              interview_block.save
            when 'EVENING'
              interview_block.evening_interviews = interview_block.evening_interviews + 1
              interview_block.save
            else
            end

            interview = Interview.new unless (interview = Interview.where(prospect_id: prospect.id).first)
            interview.interview_block_id = interview_block_id
            interview.interview_slot_id = interview_block.interview_slots.first.id
            interview.time_type = interview_block_type
            interview.prospect_id = prospect.id
            interview.save
          end
        end
      end
    end

    if params[:events]
      events = Event.where(id: params[:events].keys).includes(:office_manager)
      events.each do |event|
        event.update(notes: params[:events][event.id.to_s][:notes])
      end
    end

    if params[:gig_requests] && !(params[:gig_requests].nil?)
      gig_requests = GigRequest.where(id: params[:gig_requests].keys).includes(:prospect, :event, :job)
      gig_requests.each do |gig_request|
        gig_request.update(notes: params[:gig_requests][gig_request.id.to_s][:notes])
      end
    end

    if params[:gigs] && !(params[:gigs].nil?)
      gigs = Gig.where(id: params[:gigs].keys).includes(:prospect, :event)
      gigs.each do |gig|
        gig.update(notes: params[:gigs][gig.id.to_s][:notes])
      end
    end

    if params[:events] && !(params[:gigs].nil?)
      gigs = Gig.where(id: params[:gigs].keys).includes(:prospect, :event)
      gigs.each do |gig|
        gig.update(notes: params[:gigs][gig.id.to_s][:notes])
      end
    end

    send_mail(*mails)

    render json: OfficeZoneSync.get_synced_response
  end

  def ignore_prospect(prospect)
    remove_upcoming_gigs(prospect.gigs.joins(:event).where('events.date_start > current_date'))
  end

  def deactivate_account(prospect, is_applicant)

    if is_applicant == true
      prospect.applicant_status = nil
      prospect.save
      send_mail(StaffMailer.applicant_deactivated_due_to_inactivity(prospect))
      prospect.destroy
    else
      upcoming_gigs = prospect.gigs.joins(:event).where('events.date_start > current_date')
      if (prospect.gigs - upcoming_gigs).empty?
        send_mail(StaffMailer.employee_deactivated_account_no_contracts_worked(prospect, upcoming_gigs))
      else
        send_mail(StaffMailer.employee_deactivated_account_contracts_worked(prospect, upcoming_gigs))
      end

      prospect.gig_requests.each { |gr| Deletion.create!(table: 'gig_requests', record_id: gr.id) if gr.destroy }

      remove_upcoming_gigs(upcoming_gigs)

      if Gig.where(prospect_id: prospect.id).empty?
        prospect.destroy
      end
    end
  end

  def remove_upcoming_gigs(upcoming_gigs)
    upcoming_gigs.each do |gig|
      if PayWeek.where(prospect_id: gig.prospect_id, event_id: gig.event_id).empty?
        gig.destroy
      else
        # If there are associated tax weeks, then just make the gig inactive
        gig.status = 'Inactive'
        gig.save!
      end
    end
  end

  def blacklist_employee
    prospect = Prospect.find(params[:id])
    if prospect.status != 'HAS_BEEN'
      gig_names = Gig.where(prospect_id: prospect.id).map {|gig| gig.event.name }

      deleted_gig_names = []
      Gig.joins(:event).where("gigs.prospect_id = #{prospect.id} AND events.date_start > current_date").each do |gig|
        deleted_gig_names << gig.event.name
        gig.destroy
      end

      deleted_gig_request_names = []
      GigRequest.where(prospect_id: prospect.id).each do |gig_request|
        deleted_gig_request_names << gig_request.event.name unless gig_names.include?(gig_request.event.name)
        gig_request.destroy
      end

      if params[:lognote].present? || (params[:reason].present? && params[:include_reason_in_log].present?)
        notes = prospect.notes || ''
        notes << "\n\n" unless notes.empty?

        notes << "BLACKLISTED"
        if !deleted_gig_request_names.empty? || !deleted_gig_names.empty?
          notes << " and deleted"
          notes << " gig requests (#{deleted_gig_request_names.to_sentence})" unless deleted_gig_request_names.empty?
          notes << " and" if !deleted_gig_request_names.empty? && !deleted_gig_names.empty?
          notes << " future gigs (#{deleted_gig_names.to_sentence})" unless deleted_gig_names.empty?
        end
        notes << " for this reason: "
        notes << params[:lognote] if params[:lognote].present?
        notes << ". " if params[:lognote].present? && params[:reason].present? && params[:include_reason_in_log].present?
        notes << params[:reason] if params[:reason].present? && params[:include_reason_in_log].present?
        prospect.update_column(:notes, notes)
      end

      if params[:send_email]
        if prospect.applicant?
          send_mail(StaffMailer.applicant_blacklisted(prospect, params[:reason]))
        else
          send_mail(StaffMailer.employee_blacklisted(prospect, params[:reason]))
        end
      end

      prospect.status = 'HAS_BEEN'
      prospect.save
    else
      message = "#{prospect.first_name} #{prospect.last_name} is already a Has-Been"
    end
    render json: OfficeZoneSync.get_synced_response({message: message})
  end

  def generate_forgot_password_text
    #Only people logged in the office zone are able to call this routine.
    user = Prospect.find(params[:id])
    if user.account
      user.account.generate_one_time_token!
      mail = PublicMailer.forgot_password(user)
      @email_address = user.email
      @subject = mail.subject.html_safe
      @body = mail.body.to_s.html_safe
      @error = nil
    else
      @error = "This user does not have an account setup. Please have them register."
    end
  end

  def unlock_account
    account = Account.where(user_id: params[:id]).first
    if account
      if account.locked
        account.locked = false
        account.failed_attempts = 0
        account.save!
        render json: {status: "ok", message: "Account unlocked"}
      else
        render json: {status: "error", message: "Account wasn't locked"}
      end
    else
      render json: {status: "error", message: "This user does not have an account setup."}
    end
  end

# NAME:        prospect_scanned_dbses
# DESCRIPTION: Send data for popup dialog which shows scanned ID for Prospect
def prospect_scanned_dbses
  prospect = Prospect.find(params[:id])
  scanned_dbses = ScannedDbs.where(prospect_id: prospect.id)
  if scanned_dbses.present?
    render json: {status: 'ok', name: prospect.name, prospect_name: prospect.name, prospect_id: prospect.id, dbs_certificate_number: prospect.dbs_certificate_number,
                  dbs_issue_date: prospect.dbs_issue_date.try(:to_print), dbs_qualification_type: prospect.dbs_qualification_type,
                  scanned_dbses: scanned_dbses.map { |scanned| { id: scanned.id, extension: File.extname(scanned.photo) } }}
  else
    render json: {status: "error", message: "No scanned DBS images are on file for that Prospect."}
  end
end

# NAME:        prospect_scanned_ids
# DESCRIPTION: Send data for popup dialog which shows scanned ID for Prospect
  def prospect_scanned_ids
    prospect = Prospect.find(params[:id])
    scanned_ids = ScannedId.where(prospect_id: prospect.id)
    if scanned_ids.present?
      render json: {status: 'ok', name: prospect.name, prospect_id: prospect.id, id_number: prospect.id_number,
                    id_expiry: prospect.id_expiry.try(:to_print), id_type: prospect.id_type, nationality: prospect.nationality_id,
                    visa_number: prospect.visa_number, visa_issue_date: prospect.visa_issue_date.try(:to_print),
                    visa_expiry: prospect.visa_expiry.try(:to_print), visa_indefinite: prospect.visa_indefinite,
                    ni_number: prospect.ni_number, date_of_birth: prospect.date_of_birth.try(:to_print),
                    scanned_ids: scanned_ids.map { |scanned| { id: scanned.id, extension: File.extname(scanned.photo) } },
                    has_share_code_file: prospect.share_code_files.count > 0, condition: prospect.condition,
                    id_sighted: prospect.id_sighted.try(:to_print), share_code: prospect.share_code}
    else
      render json: {status: "error", message: "No scanned ID images are on file for that Prospect."}
    end
  end

  def approve_ids
    prospect = Prospect.find(params[:id])

    if prospect.nationality.others? && prospect.share_code_files.blank?
      return render json: { status: 'error', message: 'Please include the share code pdf file' }
    end

    if prospect.scanned_ids.present?
      prospect.id_sighted  = Date.today
      prospect.id_number   = params[:id_number] if params[:id_number].present?
      prospect.visa_number = params[:visa_number] if params[:visa_number].present?
      prospect.visa_expiry = params[:visa_expiry].to_date if params[:visa_expiry].present?
      prospect.date_of_birth = params[:date_of_birth].to_date if params[:date_of_birth].present?
      prospect.nationality_id = params[:nationality_id].to_i if params[:nationality_id].present?
      prospect.ni_number = params[:ni_number] if params[:ni_number].present?

      if prospect.valid? && prospect.save
        send_mail(StaffMailer.employee_id_approved(prospect))
        todo_id = todo_id_for_id_approval(prospect) # see comment in #get_todos
        # Normally OfficeZoneSync takes care of deletions, but since the todo is not a real model, we have to do it manually
        Deletion.create!(table: 'todos', record_id: todo_id)
      end
      render json: OfficeZoneSync.get_synced_response({deleted: {todos: [todo_id]}})
    else
      render json: {status: 'ok'}
    end
  end

  def reject_ids
    prospect = Prospect.find(params[:id])
    prospect.scanned_ids.destroy_all
    prospect.id_sighted = nil
    prospect.id_type = nil
    prospect.id_number = nil
    prospect.visa_number = nil
    prospect.visa_expiry = nil
    prospect.save

    send_mail(StaffMailer.employee_id_rejected(prospect, params[:reason])) if params[:send_email]

    # Normally OfficeZoneSync takes care of deletions, but since the todo is not a real model, we have to do it manually
    todo_id = todo_id_for_id_approval(prospect) # see comment in #get_todos
    Deletion.create!(table: 'todos', record_id: todo_id)
    render json: OfficeZoneSync.get_synced_response({deleted: {todos: [todo_id]}})
  end

  # NAME:        scanned_id_image
  # DESCRIPTION: Serve up one of the scanned ID images
  def scanned_id_image
    # scanned_id = ScannedId.find(params[:id])
    scanned_id = ScannedId.where(id: params[:id]).first

    if scanned_id
      sub_dir_name = params[:large] ? 'scanned_ids_large' : 'scanned_ids'
      file_path = File.join(Flair::Application.config.shared_dir, sub_dir_name, scanned_id.photo)
      if File.exist?(file_path)
        send_file(file_path, filename: scanned_id.photo, disposition: 'inline')
      else
        render json: {status: 'ok'}
      end
    else
      render json: {status: 'error'}
    end
  end

  # NAME:        share_code_file
  # DESCRIPTION: Serve up one of the share code file
  def share_code_file
    share_code_file = ShareCodeFile.where(prospect_id: params[:id]).last

    if share_code_file
      file_path = File.join(Flair::Application.config.shared_dir, 'prospect_share_codes', share_code_file.path)
      if File.exist?(file_path)
        send_file(file_path, filename: share_code_file.path, disposition: 'inline')
      else
        render json: {status: 'ok'}
      end
    else
      render json: {status: 'error'}
    end
  end

  # NAME:        scanned_dbs_image
  # DESCRIPTION: Serve up one of the scanned ID images
  def scanned_dbs_image
    scanned_id = ScannedDbs.find(params[:id])
    sub_dir_name = params[:large] ? 'scanned_dbses_large' : 'scanned_dbses'
    file_path = File.join(Flair::Application.config.shared_dir, sub_dir_name, scanned_id.photo)
    if File.exist?(file_path)
      send_file(file_path, filename: scanned_id.photo, disposition: 'inline')
    else
      render json: {status: 'ok'}
    end
  end

  def upload_scanned_dbses
    @prospect = Prospect.find(params[:id])

    if request.post?
      small_dir = File.join(Flair::Application.config.shared_dir, 'scanned_dbses')
      large_dir = File.join(Flair::Application.config.shared_dir, 'scanned_dbses_large')
      errors = []

      @prospect.scanned_dbses.destroy_all

      accept_upload = lambda do |upload, name|
        file_format = upload.original_filename.split('.').last
        result = handle_general_upload(upload, small_dir, "#{@prospect.id}_#{name}.#{file_format}", {width: 400, height: 400})
        if result == :ok
          if file_format != 'pdf'
            upload.rewind
            result = handle_general_upload(upload, large_dir, "#{@prospect.id}_#{name}.#{file_format}", {width: 800, height: 800})
          end
          if result == :ok
            @prospect.scanned_dbses.create!(photo: "#{@prospect.id}_#{name}.#{output_file_format(File.extname(upload.original_filename))}")
          else
            errors << "Error for Scan #1: #{result}"
          end
        else
          errors << "Error for Scan #1: #{result}"
        end
      end

      accept_upload[params[:id_1], "id1"] if params[:id_1]
      accept_upload[params[:id_2], "id2"] if params[:id_2]

      if errors.empty?
        if @prospect.scanned_dbses.present?
          @prospect.dbs_certificate_number = params[:dbs_certificate_number] if params[:dbs_certificate_number].present?
          @prospect.is_convicted = params[:is_convicted] == 'true'
          @prospect.is_clean = params[:is_clean] == 'true'
          @prospect.dbs_qualification_type = params[:dbs_qualification_type] if params[:dbs_qualification_type].present?
          @prospect.dbs_issue_date = params[:dbs_issue_date].to_date if params[:dbs_issue_date].present?
          # TODO: Probably should change the whole DBS thing to the prospect model.
          # @prospect.qualification_dbs = true
          @prospect.questionnaire.dbs_qualification = true
          @prospect.questionnaire.save!
          @prospect.save!
          render html: "<h2>Uploaded!</h2>".html_safe
        else
          render html: "<h2>You need to choose at least one file.</h2>".html_safe
        end
      else
        render html: "<p><ul>#{errors.map { |e| "<li>#{e}</li>" }.join}</ul></p><p><a href='/office/upload_scanned_dbses'>Try again</a></p>".html_safe
      end
    end
  end

  def upload_scanned_ids
    @prospect = Prospect.find(params[:id])

    if request.post?
      small_dir = File.join(Flair::Application.config.shared_dir, 'scanned_ids')
      large_dir = File.join(Flair::Application.config.shared_dir, 'scanned_ids_large')
      errors = []

      accept_upload = lambda do |upload, name|
        file_format = upload.original_filename.split('.').last
        result = handle_general_upload(upload, small_dir, "#{@prospect.id}_#{name}.#{file_format}", {width: 400, height: 400})
        if result == :ok
          if file_format != 'pdf'
            upload.rewind
            result = handle_general_upload(upload, large_dir, "#{@prospect.id}_#{name}.#{file_format}", {width: 800, height: 800})
          end
          if result == :ok
            @prospect.scanned_ids.create!(photo: "#{@prospect.id}_#{name}.#{output_file_format(File.extname(upload.original_filename))}")
          else
            errors << "Error for Scan #1: #{result}"
          end
        else
          errors << "Error for Scan #1: #{result}"
        end
      end
      
      if params[:id_1] || params[:id_2] || params[:id_3]
        @prospect.scanned_ids.destroy_all
      end

      accept_upload[params[:id_1], "id1"] if params[:id_1]
      accept_upload[params[:id_2], "id2"] if params[:id_2]
      accept_upload[params[:id_3], "id3"] if params[:id_3]


      if errors.empty?
        if @prospect.scanned_ids.present?
          @prospect.id_sighted  = Date.today
          @prospect.id_type  = params[:id_type] if params[:id_type].present?
          @prospect.id_number   = params[:id_number] if params[:id_number].present?
          @prospect.id_expiry = params[:id_expiry].to_date if params[:id_expiry].present?
          @prospect.visa_number = params[:visa_number] if params[:visa_number].present?
          @prospect.visa_expiry = params[:visa_expiry].to_date if params[:visa_expiry].present?
          @prospect.visa_indefinite = params[:visa_indefinite] == 'true'
          @prospect.date_of_birth = params[:date_of_birth].to_date if params[:date_of_birth].present?
          @prospect.nationality_id = params[:nationality_id].to_i if params[:nationality_id].present?
          @prospect.ni_number = params[:ni_number] if params[:ni_number].present?
          @prospect.condition = params[:condition] if params[:condition].present?
          unless @prospect.save
            return render html: "<h2>#{@prospect.errors.full_messages.to_sentence}</h2>".html_safe
          end
        else
          return render html: "<h2>You need to have at least one ID image.</h2>".html_safe
        end

        if @prospect.nationality.others?
          @prospect.share_code  = params[:share_code].upcase if params[:share_code].present?
          unless @prospect.save
            return render html: "<h2>#{@prospect.errors.full_messages.to_sentence}</h2>".html_safe
          end
          
          if params[:share_code_file].present?
            uploaded = params[:share_code_file]
            file_format = uploaded.original_filename.split('.').last
            path = "#{@prospect.id}_#{@prospect.share_code}.#{file_format}"

            @prospect.share_code_files.destroy_all

            directory = File.join(Flair::Application.config.shared_dir, 'prospect_share_codes')
            result = handle_pdf_upload(uploaded, directory, path)
            if result == :ok
              @prospect.share_code_files.create!(path: path)
            else
              return render html: "<h2>Error for Scan: #{result}</h2>"
            end

            if @prospect.share_code.blank? || @prospect.share_code_files.blank?
              return render html: "<h2>You need to send the Share Code and at least one Share Code file for that nationality.</h2>".html_safe
            end
          end
        end
        render html: "<h2>Uploaded!</h2>".html_safe
      else
        render html: "<p><ul>#{errors.map { |e| "<li>#{e}</li>" }.join}</ul></p><p><a href='/office/upload_scanned_ids'>Try again</a></p>".html_safe
      end
    end
  end

  # Finds a ScannedId and rotates it 90deg clockwise
  def rotate_scanned_id
    scan = ScannedId.find(params[:id])
    scan.rotate
    scan.touch
    scan.prospect.touch
    render json: {status: 'ok'}
  end

    # Finds a ScannedBarLicense and rotates it 90deg clockwise
    def rotate_scanned_dbs
      scan = ScannedDbs.find(params[:id])
      scan.rotate
      scan.touch
      scan.prospect.touch
      render json: {status: 'ok'}
    end

  # Finds a ScannedBarLicense and rotates it 90deg clockwise
  def rotate_scanned_bar_license
    scan = ScannedBarLicense.find(params[:id])
    scan.rotate
    scan.touch
    scan.prospect.touch
    render json: {status: 'ok'}
  end

  def upload_prospect_photo
    @prospect = Prospect.find(params[:id])

    if request.post?
      errors = []
      if uploaded = params[:photo]
        directory = File.join(Flair::Application.config.shared_dir, 'prospect_photos')
        result    = handle_image_upload(uploaded, directory, @prospect.id.to_s, Prospect::PROSPECT_THUMBNAIL_SIZE)
        case result
          when :ok
            @prospect.update_column(:photo, "#{@prospect.id}.#{FileUploads::FILE_FORMAT}")
            @prospect.update_column(:has_large_photo, true)
          when :thumbnail_failed
            errors << "A server error occurred while processing #{uploaded.original_filename}. The file may be corrupted. If this happens every time you try to upload this file, please contact Flair for help."
          when :not_enough_space
            errors << "Sorry, there is not enough free space on the server's hard drive to store your photo."
          when :too_large
            errors << "Photo files cannot be larger than 20 megabytes. Please upload a different photo file."
          when :unknown_image_type
            errors <<  "Photo files must be .jpg, .jpeg, .gif, or .png files. Please upload a different photo file."
          when :blank
            errors <<  "Please use the upload button to choose a picture before submitting"
          else
            errors << "Error for photo: #{result}"
        end
      end

      if errors.empty?
        render html: "<h2>Uploaded!</h2>".html_safe
      else
        render html: "<p><ul>#{errors.map { |e| "<li>#{e}</li>" }.join}</ul></p><p><a href='/office/upload_prospect_photo'>Try again</a></p>".html_safe
      end
    end
  end

  def upload_share_code
    @prospect = Prospect.find(params[:id])

    if request.post? && params[:file].present?
      errors = []
      uploaded = params[:file]
      file_format = params[:file].original_filename.split('.').last
      path = "#{@prospect.id}_#{@prospect.share_code}.#{file_format}"

      @prospect.share_code_files.destroy_all

      directory = File.join(Flair::Application.config.shared_dir, 'prospect_share_codes')
      result    = handle_pdf_upload(uploaded, directory, path)
      case result
        when :ok
          @prospect.share_code_files.create!(path: path)
        when :not_enough_space
          errors << "Sorry, there is not enough free space on the server's hard drive to store your photo."
        when :not_pdf
          errors << "The file sent is not a PDF."
        else
          errors << "Error for file: #{result}"
      end

      if errors.empty?
        head :ok
      else
        render plain: errors.join(','), status: 422
      end
    end
  end

  def reject_photo
    prospect = Prospect.find(params[:id])
    message = nil
    if prospect.photo
      directory = File.join(Flair::Application.config.shared_dir, 'prospect_photos')
      path = directory + '/' + prospect.photo
      if File.exist?(path)
        File.delete(path)
        prospect.photo = nil
        prospect.has_large_photo = false
        prospect.save!
        send_mail(StaffMailer.photo_rejected(prospect))
        message = "Photo Rejection Email Sent"
      end
    end
    render json: {status: 'ok', message: message}
  end

  # NAME:        scanned_id_image
  # DESCRIPTION: Serve up one of the scanned ID images
  def prospect_scanned_bar_licenses
    prospect = Prospect.find(params[:id])
    scanned_bar_licenses = ScannedBarLicense.where(prospect_id: prospect.id)
    if scanned_bar_licenses.present?
      render json: {status: 'ok', name: prospect.name, prospect_id: prospect.id, bar_license_no: prospect.bar_license_no, bar_license_type: prospect.bar_license_type,
                    bar_license_issued_by: prospect.bar_license_issued_by, bar_license_expiry: prospect.bar_license_expiry.try(:to_print),
                    scanned_bar_licenses: scanned_bar_licenses.map { |scanned| { id: scanned.id, extension: File.extname(scanned.photo) } }}
    else
      render json: {status: "error", message: "No scanned bar license images are on file for that employee."}
    end
  end
  def scanned_bar_license_image
    scanned_bar_license = ScannedBarLicense.find(params[:id])
    sub_dir_name = params[:large] ? 'scanned_bar_licenses_large' : 'scanned_bar_licenses'
    file_path = File.join(Flair::Application.config.shared_dir, sub_dir_name, scanned_bar_license.photo)
    if File.exist?(file_path)
      send_file(file_path, filename: scanned_bar_license.photo, disposition: 'inline')
    else
      render json: {status: 'ok'}
    end
  end

  def upload_scanned_bar_license
    @prospect = Prospect.find(params[:id])

    if request.post?
      small_dir = File.join(Flair::Application.config.shared_dir, 'scanned_bar_licenses')
      large_dir = File.join(Flair::Application.config.shared_dir, 'scanned_bar_licenses_large')
      errors = []

      @prospect.scanned_bar_licenses.destroy_all

      accept_upload = lambda do |upload, name|
        file_format = upload.original_filename.split('.').last
        result = handle_general_upload(upload, small_dir, "#{@prospect.id}_#{name}", {width: 400, height: 400})
        if result == :ok
          if file_format != 'pdf'
            upload.rewind
            result = handle_general_upload(upload, large_dir, "#{@prospect.id}_#{name}", {width: 800, height: 800})
          end
          if result == :ok
            @prospect.scanned_bar_licenses.create!(photo: "#{@prospect.id}_#{name}.#{output_file_format(File.extname(upload.original_filename))}")
          else
            errors << "Error for Scan #{name}: #{result}"
          end
        else
          errors << "Error for Scan #{name}: #{result}"
        end
      end

      accept_upload[params[:id_1], "id1"] if params[:id_1]
      accept_upload[params[:id_2], "id2"] if params[:id_2]

      if errors.empty?
        @prospect.bar_license_type  = params[:bar_license_type] if params[:bar_license_type].present?
        @prospect.bar_license_no   = params[:bar_license_no] if params[:bar_license_no].present?
        @prospect.bar_license_issued_by = params[:bar_license_issued_by] if params[:bar_license_issued_by].present?
        @prospect.bar_license_expiry = params[:bar_license_expiry].to_date if params[:bar_license_expiry].present?
        @prospect.save!
        render html: "<h2>Uploaded!</h2>".html_safe
      else
        render html: "<p><ul>#{errors.map { |e| "<li>#{e}</li>" }.join}</ul></p><p>Press the back button and try again</p>".html_safe
      end
    end
  end

# NAME:        create_event
# DESCRIPTION: As above
  def create_event
    params[:event][:post_code].strip! if params[:event][:post_code]

    event = Event.new
    event_params(params[:event]).reject { |k,v| v.blank? }.each do |k,v|
      send_to_object(event, k, v)
    end

    errors = []

    if !params[:event_clients] || params[:event_clients].all?(&:blank?)
      errors << "Must Specify a Client"
    else
      if event.save
        associate_clients_with_event(event.id, params[:event_clients])
        EventClient.where(event_id: event.id).each do |event_client|
          booking = Booking.new(event_client_id: event_client.id)
          booking.save
        end
        #Create default event_dates
        dates_to_create = []
        if (event.date_end - event.date_start).to_i < 7
          (event.date_start..event.date_end).each do |date|
            dates_to_create << date
          end
        else
          dates_to_create << event.date_start
        end
        dates_to_create.each do |date|
          event_date = EventDate.new
          event_date.event_id = event.id
          event_date.date = date
          event_date.save
        end
        if event.show_in_ongoing
          generate_ongoing_tasks(event.id)
        end
      end
    end



    render json: OfficeZoneSync.get_synced_response({message: errors.any? ? errors.to_sentence : nil})
  end

  # NAME:        update_event
  # DESCRIPTION: More of the same
  def update_event
    params[:events] = {}
    params[:events][params[:id]] = params[:event]
    params[:events][params[:id]][:event_clients] = params[:event_clients].reject { |c| c.blank? } if params[:event_clients]
    params[:events][params[:id]][:event_dates] = params[:event_dates]
    params[:events][params[:id]][:booking] = params[:booking]
    params[:events][params[:id]][:client_contact] = params[:client_contact]
    if Event.exists? params[:id]
      update_events
    else
      render json: {status: "ok", message: "Event was previously deleted.", deleted: {events: params[:id]}}
    end
  end

  def update_events
    errors = []
    message = nil
    if params[:events]
      events = Event.find(params[:events].keys)
      events.each do |event|
        if event.closed? && current_user.staffer?
          errors << 'Only Managers can edit details for closed events.'
          next
        end
        is_ongoing_event = event.show_in_ongoing

        # save job info if there is any
        if params[:job]
          if params[:job][:id] != "" && params[:job][:id] != nil
            job = Job.find(params[:job][:id])
            job.new_description = params[:job][:new_description]
            job.uniform_information = params[:job][:uniform_information]
            job.shift_information = params[:job][:shift_information]
            job.updated_at = Time.now
            job.save

            jobs = job.event.jobs

            jobs.each do |job|
              puts "------------ #{Time.now + rand()} ----------"
              job.updated_at = Time.now + rand()
              puts '----------------------'
              job.save
            end
          end
        end

        #Sanitize Attributes
        attrs = params[:events][event.id.to_s]
        attrs[:post_code].strip! if attrs[:post_code]
        attrs[:leader_meeting_location_coords] = attrs[:leader_meeting_location_coords].gsub(/\s+/, '').gsub(',', ', ') if attrs[:leader_meeting_location_coords]

        event_params(attrs.except(:event_clients, :event_dates, :booking, :client_contact)).each do |k,v|
          send_to_object(event, k, v) unless event[k].blank? and v.blank?
        end

        # Update Event Dates
        # This is done before validating the event to give the user a chance to adust calendar days before running
        # related validation on event date start and end
        if attrs[:event_dates]
          dates = attrs[:event_dates].split(',').map {|date_string| Date.strptime(date_string, "%d/%m/%Y")}
          existing_dates = event.event_dates.pluck :date

          dates_to_create = dates - existing_dates
          dates_to_create.each do |date|
            event_date = EventDate.new
            event_date.event_id = event.id
            event_date.date = date
            event_date.save
          end

          dates_to_destroy = existing_dates - dates

          if dates_to_destroy.any?
            dates_to_destroy.each do |date|
              event_date_shift = Shift.where(event: event, date: date)
              if event_date_shift.any?
                errors.push("Event Date #{date} not removed, shift already present")
              else
                EventDate.where(event: event, date: date).destroy_all 
              end
            end
          end
        end

        if event.valid?
          #Update Event_client joins table
          if attrs[:event_clients]
            event_clients = associate_clients_with_event(event.id, attrs[:event_clients])

            # Create a blank booking for any added clients
            event_clients[:added].each do |event_client|
              Booking.create(event_client_id: event_client.id)
            end
          end

          errors << 'Must Specify a Client' if event.clients.blank?

          #When Default Job/Location is set, also set the jobs for gigs with unassigned jobs
          if event.default_job_id_changed?
            gigs = event.gigs.includes(:prospect).where("job_id IS NULL").each do |gig|
              gig.job_id = event.default_job_id
              gig.save
            end
          end

          if event.default_location_id_changed?
            gigs = event.gigs.includes(:prospect).where("location_id IS NULL").each do |gig|
              gig.location_id = event.default_location_id
              gig.save
            end
          end

          update_payroll = event.paid_breaks_changed?
          generate_tasks = false
          generate_ongoing_tasks = false
          if event.size_id_changed?
            if event.size_id_change[0] == nil && event.event_tasks.length == 0
              generate_tasks = true
              message = "Generated Event Planner Tasks"
            else
              message = "You changed the Event Size, but Event Planner Tasks were NOT regenerated. Please add/remove planner tasks manually."
            end
          end
          if !generate_tasks && event.office_manager_id_changed? && event.event_tasks.length > 0
            update_office_manager_on_tasks = true
            previous_office_manager_id = event.office_manager_id_was
          end

          remove_flag_photo(event, attrs)

          if attrs[:status] == 'FINISHED'
            prospects = Prospect.where(id: event.gigs.distinct.pluck(:prospect_id))
            prospects.each do |prospect|
              if prospect.completed_contracts.nil?
                prospect.completed_contracts = 1
              else
                prospect.completed_contracts = prospect.completed_contracts + 1
              end
              prospect.save
            end
          end

          if attrs[:show_in_ongoing].present? && attrs[:show_in_ongoing].to_i == 1 && is_ongoing_event == false
            event.event_tasks.destroy_all
            generate_ongoing_tasks = true
          end

          event.save

          # If the paid_breaks changed, then we need to resave the timesheets to trigger a recalculate of the payroll
          if update_payroll
            event.gigs.each do |gig|
              gig.timesheet_entries.select { |tse| %w(NEW PENDING).include?(tse.status)}.each do |timesheet_entry|
                timesheet_entry.save
              end
            end
          end

          if generate_tasks
            generate_event_tasks(event.id)
          end

          if generate_ongoing_tasks
            generate_ongoing_event_tasks(event.id)
          end

          if update_office_manager_on_tasks
            event.event_tasks.includes(:officer, :tax_week).where.not(completed: true).each do |et|
              et.officer_id = event.office_manager_id
              et.save
            end
          end

          if attrs[:booking]
            if EventClient.where(event_id: event.id).none?
              errors << "You must select a client"
            else
              client_id = attrs[:booking][:client_id]
              if client_id
                event_client = EventClient.where(client_id: client_id, event_id: event.id).first
                if event_client
                  booking = Booking.where(event_client_id: event_client.id).first_or_create
                  booking_attributes = booking_params(attrs[:booking].except(:client_id, :amendments, :health_safety_template))
                  track_amendments = (event.status != 'BOOKING')
                  booking_attributes.each do |k,v|
                    if booking[k] != v
                      if !booking[k].blank? && booking.id && track_amendments
                        booking.amendments = "#{DateTime.now.strftime('%d/%m/%y %H:%M:%S')} (#{current_user.last_name}, #{current_user.first_name}) #{k.humanize}: \"#{v}\"\n" + (booking.amendments || '')
                      end
                      send_to_object(booking, k, v) unless booking[k].blank? and v.blank?
                    end
                  end
                  booking.event_client_id = EventClient.where(event_id: event.id, client_id: params[:booking][:client_id]).first.id

                  booking.event_client_id = event_client.id
                  if booking.valid?
                    if attrs[:client_contact]
                      if attrs[:client_contact][:id] == "-1"
                        cc = ClientContact.new
                        cc.first_name = attrs[:client_contact][:first_name]
                        cc.last_name  = attrs[:client_contact][:last_name]
                        cc.mobile_no  = attrs[:client_contact][:mobile_no]
                        cc.email      = attrs[:client_contact][:email]
                        cc.client_id  = client_id
                        if cc.save
                          booking.client_contact_id = cc.id
                        end
                      elsif attrs[:client_contact][:id] == "0"
                        booking.client_contact_id = nil
                      else
                        booking.client_contact_id = attrs[:client_contact][:id]
                      end
                    end

                    booking.save
                  end
                end
              end
            end
          end
        end
      end
    end
    render json: OfficeZoneSync.get_synced_response({message: errors.any? ? errors.to_sentence : message})
  end

  def get_jobs
    description = ""
    shift = ""
    uniform = ""
    if params[:job_id] != nil && params[:job_id] != ""
      job = Job.find_by(id: params[:job_id])

      if job
        description = job.new_description
        main_description = job.description
        shift = job.shift_information
        uniform = job.uniform_information
      end
    end
    render json: {description: description, shift: shift, uniform: uniform, main_description: main_description}
  end

  def get_no_of_interviews
    interview_block = InterviewBlock.find(params[:interview_block_id])

    return render json: {
      morning_interviews: interview_block.morning_interviews,
      afternoon_interviews: interview_block.afternoon_interviews,
      evening_interviews: interview_block.evening_interviews
    }
  end

  def save_job
    if request.post?
      job = Job.find(params[:job_id])
      job.new_description = params[:new_description]
      job.uniform_information = params[:uniform_information]
      job.shift_information = params[:shift_information]
      Rails.logger.warn "----------------------------------------------------Save Job ------------------------"
      Rails.logger.warn  job.save!
      puts "--------------------------- check2------------------------"

      render json: {status: :success}
    end
  end

  def put_opening_word_to_job
    Event.all.includes(:jobs).each do |event|
      opening_words = event.blurb_opening ? event.blurb_opening : ""
      job_info = event.blurb_job ? event.blurb_job : ""
      shift_info = event.blurb_shift ? event.blurb_shift : ""
      uniform_info = event.blurb_uniform ? event.blurb_uniform : ""

      event.jobs.each do |job|
        if job.new_description == nil || job.new_description == ""
          job.update(new_description: "#{opening_words} #{job_info}")
        end

        if job.shift_information == nil || job.shift_information == ""
          job.shift_information = shift_info
        end

        if job.uniform_information == nil || job.uniform_information == ""
          job.uniform_information = uniform_info
        end
      end
    end

    render json: :success
  end

  def duplicate_job_info
    if request.post?
      job = Job.find(params[:job_id])
      new_description = params[:new_description]
      uniform_information = params[:uniform_information]
      shift_information = params[:shift_information]
      jobs = job.event.jobs

      jobs.each do |job|
        job.update(new_description: new_description)
        job.update(uniform_information: uniform_information)
        job.update(shift_information: shift_information)
        Rails.logger.warn "----------------------------------------------------duplicate Job ------------------------"

        job.save!
        Rails.logger.warn  "--------------------------- check------------------------"
        # render json: {description: new_description, shift: shift_information, uniform: uniform_information}
        # if job.new_description == nil || job.new_description == ""
        #   job.update(new_description: new_description)
        # end
        #
        # if job.uniform_information == nil || job.uniform_information == ""
        #   job.update(uniform_information: uniform_information)
        # end
        #
        # if job.shift_information == nil || job.shift_information == ""
        #   job.update(shift_information: shift_information)
        # end
      end

      render json: {status: :success}
    end
  end

  def remove_flag_photo(event, attrs)
    if attrs[:status] == 'FINISHED'
      prospects = Prospect.where(id: event.gigs.distinct.pluck(:prospect_id))
      prospects.each do |prospect|
        prospect.flag_photo = nil
        prospect.save
      end
    end
  end

  # NAME:        remove_event_tasks
  # DESCRIPTION: remove all the event tasks
  def remove_event_tasks
	  event = Event.find(params[:id].to_i)
	  event.size_id = nil
	  event.event_tasks.destroy_all
	  event.save

	  render json: OfficeZoneSync.get_synced_response
  end

  def associate_clients_with_event(event_id, client_ids)
    new_event_clients = []
    client_ids ||= []
    client_ids = client_ids.reject {|c| c.blank?}
    client_ids = client_ids.map {|c| c.to_i}
    EventClient.includes(:client, :booking, :invoices).where(event_id: event_id).each do |event_client|
      if client_ids.include? event_client.client_id
        #Remove client_ids that are no longer there, don't bother changing ones that already exist
        client_ids.delete(event_client.client_id)
      else
        #Delete event_clients that have been removed
        event_client.booking.try(:destroy)
        event_client.destroy
      end
    end
    client_ids.each do |client_id|
      #Add new events
      event_client = EventClient.new
      event_client.event_id = event_id
      event_client.client_id = client_id
      event_client.save
      new_event_clients << event_client
    end
    { added: new_event_clients }
  end

# NAME:        delete_event
# DESCRIPTION: delete Event from DB *if* it is New
  def delete_event
    render_if_nonexistent(Event, params[:id], nil); return if performed?
    Event.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  # NAME:        duplicate_event
  # DESCRIPTION: Duplicate an event, but skip some fields
  def duplicate_event
    render_if_nonexistent(Event, params[:id], "The original event has already been deleted"); return if performed?
    old_event = Event.find(params[:id])
    event = Event.new

    data = {}

    new_name = old_event.name
    loop do
      prev_name = new_name
      new_name = increment_event_name(new_name)
      break if Event.where(name: new_name).none?
      raise "Could not increment name #{new_name}" if prev_name == new_name #infinite loop safety
    end
    event.name = new_name
    event.display_name = old_event.display_name

    #Copy attributes (except for the ones we don't want)
    attributes_to_skip = %w(date_start date_end id name display_name date_callback_due status created_at updated_at photo default_job_id default_location_id gigs_count admin_completed site_manager expense_notes requires_booking blurb_legacy default_assignment_id size_id) +
                         Event.column_names.select {|name| /^accom_/.match(name)}

    (event.attribute_names - attributes_to_skip).each do |a|
      event[a] = old_event[a]
    end

    date_offset = 52.weeks
    [:date_start, :public_date_start, :date_end, :public_date_end].each { |a| event[a] = old_event[a] + date_offset }

    if old_event.status == 'BOOKING'
      event.status = 'BOOKING'
    else
      event.status = 'NEW'
    end

    if event.valid? && event.save
      EventDate.where(event_id: old_event.id).each do |old_event_date|
        event_date = old_event_date.dup
        event_date.date = event_date.date + date_offset
        event_date.event_id = event.id
        event_date.save
      end
      if old_event.photo
        directory = File.join(Flair::Application.config.shared_dir, 'public', 'event_photos')
        old_name = old_event.photo
        new_name = old_event.photo.gsub(old_event.id.to_s, event.id.to_s)
        old_path = "#{directory}/#{old_name}"
        new_path = "#{directory}/#{new_name}"
        if File.exist?(old_path)
          FileUtils.cp(old_path, new_path)
          event.photo = new_name if File.exist?(new_path)
        end
      end
      EventClient.where(event_id: old_event.id).each do |ec|
        event_client = EventClient.new(event_id: event.id, client_id: ec.client_id)
        event_client.save

        Booking.where(event_client_id: ec.id).each do |b|
          booking = Booking.new
          booking_attributes_to_copy = booking.attribute_names - %w(id event_client_id amendments dates timings crew_required job_description transport meeting_location)
          (booking_attributes_to_copy = booking_attributes_to_copy - %w(rates wages)) unless params[:duplicate_full]
          booking_attributes_to_copy.each { |a| booking[a] = b[a]}
          booking.event_client_id = event_client.id
          booking.save
        end
      end

      if params[:duplicate_full]
        Job.where(event_id: old_event.id).each do |old_job|
          job = old_job.dup
          job.event_id = event.id
          # # duplicate
          # opening = event.blurb_opening ? event.blurb_opening : ""
          # job_info = event.blurb_job ? event.blurb_job : ""
          # if job.new_description == nil || job.new_description == ""
          #   job.new_description = "#{opening} #{job_info}"
          # end

          # shift_info = event.blurb_shift ? event.blurb_shift : ""
          # if job.shift_information == nil || job.shift_information == ""
          #   job.shift_information = shift_info
          # end

          # uniform_info = event.blurb_uniform ? event.blurb_uniform : ""
          # if job.uniform_information == nil || job.uniform_information == ""
          #   job.uniform_information = uniform_info
          # end
          job.save
        end
        Shift.where(event_id: old_event.id).each do |old_shift|
          shift = old_shift.dup
          shift.date = shift.date + date_offset
          shift.event_id = event.id
          shift.save
        end
        Location.where(event_id: old_event.id).each do |old_location|
          location = old_location.dup
          location.event_id = event.id
          location.save
        end
        Tag.where(event_id: old_event.id).each do |old_tag|
          tag = old_tag.dup
          tag.event_id = event.id
          tag.save
        end
      end

      data[:new_id] = event.id
    end
    render json: OfficeZoneSync.get_synced_response(data)
  end

  def generate_event_tasks(id)
    event = Event.includes(:size, :office_manager).find(id)

    previous_target_date = nil

    EventTaskTiming.includes(:template).where(size: event.size, type: 'BEFORE_EVENT_START').sort_by(&:days).each do |timing|
      target_task_date = event.date_start - timing.days.days

      business_date = get_closest_business_date_on_or_before_date(target_task_date)
      ##### If the target date shifted to a different date, we will offset any other adjacent dates
      if previous_target_date && target_task_date == previous_target_date - 1.day
        business_date = get_closest_business_date_on_or_before_date(business_date - 1.day)
      end
      next if business_date < Date.today

      #Use business_date to create task
      event_task = EventTask.new
      event_task.event    = event
      event_task.officer  = event.office_manager
      event_task.template = timing.template
      event_task.task     = timing.template.task
      event_task.notes    = timing.template.notes
      event_task.due_date = business_date
      event_task.save

      previous_target_date = target_task_date
    end
  end

  def generate_ongoing_event_tasks(id)
    event = Event.includes(:size, :office_manager, :event_dates).find(id)

    previous_target_date = nil

    event_admin_task = EventTaskTemplate.where(task: "Event Admin").first
    confirm_team_task = EventTaskTemplate.where(task: "Confirm Team & FD'S").first

    if event.event_dates
      event.event_dates.pluck(:tax_week_id).each do |tax_week_id|
        week = TaxWeek.find tax_week_id
        event_task = EventTask.new
        event_task.event    = event
        event_task.officer  = event.office_manager
        event_task.template = event_admin_task
        event_task.task     = event_admin_task.task
        event_task.notes    = event_admin_task.notes
        event_task.due_date = week.date_start + 1.day
        event_task.save

        event_task = EventTask.new
        event_task.event    = event
        event_task.officer  = event.office_manager
        event_task.template = confirm_team_task
        event_task.task     = confirm_team_task.task
        event_task.notes    = confirm_team_task.notes
        event_task.due_date = week.date_start + 3.day
        event_task.save
      end
    end
  end

  def create_event_task
    event_task = EventTask.new
    event_task_params(params[:event_task]).reject { |k,v| v.blank? }.each do |k,v|
      send_to_object(event_task, k, v)
    end
    event_task.task = event_task.template.try(:task) || ''
    event_task.save

    render json: OfficeZoneSync.get_synced_response
  end

  def update_event_task
    params[:event_tasks] = {}
    params[:event_tasks][params[:id]] = params[:event_task]
    if EventTask.exists? params[:id]
      update_event_tasks
    else
      render json: {status: "ok", message: "Event Task was previously deleted.", deleted: {event_tasks: params[:id]}}
    end
  end

  def update_event_tasks
    if params[:event_tasks]
      event_task_ids = params[:event_tasks].keys
      event_task_ids.each do |event_task_id|
        if (event_task = EventTask.find_by(id: event_task_id))
          attrs = params[:event_tasks][event_task_id.to_s]
          refined_event_tasks_params = event_task_params(attrs).reject { |k,v| v.blank? && event_task[k].blank? }
          if refined_event_tasks_params[:template_id].present?
	          event_task_template = EventTaskTemplate.find(refined_event_tasks_params[:template_id].to_i)
	          refined_event_tasks_params[:task] = event_task_template.task
          end
          event_task.assign_attributes(refined_event_tasks_params)
          event_task.save
        end
      end
    end

    render json: OfficeZoneSync.get_synced_response
  end

  # Yuck, this is messy. Refactor later so we don't have two separate update routines
  # This is is for task editing in the events table. The above one is for the main table in the Planner
  def update_event_tasks_from_event

    # Create a new event
    if (new_record = params[:event_tasks].delete("-1"))
      new_record[:event_id] = params[:event_id]
      new_event_task = EventTask.new(event_task_params(new_record))
      new_event_task.task = new_event_task.template.try(:task) || 'Custom'
      new_event_task.save
    end

    # Update existing event
    # TODO: When modifying a task in the Contract section the corresponding entry in the Planner does not update the template.
    # It's odd why the model#update method is not functioning. Perhaps AR is holding the old template reference?
    event_tasks = EventTask.find(params[:event_tasks].keys)
    event_tasks.each do |event_task|
      # Debugging
      # puts "Updating EventTask: #{event_task.id}"
      # puts event_task.attributes
      event_task_attributes = event_task_params(params[:event_tasks][event_task.id.to_s])
      if event_task_attributes[:template_id].present?
        event_task_template = EventTaskTemplate.find(event_task_attributes[:template_id].to_i)
        event_task_attributes[:task] = event_task_template.task
      end
      event_task.assign_attributes event_task_attributes
      event_task.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_event_task
    render_if_nonexistent(EventTask, params[:id], nil); return if performed?
    EventTask.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def get_closest_business_date_on_or_before_date(date)
    date -= 1.day  if date.wday == 6 # Saturday (1) -> Friday
    date -= 2.days if date.wday == 0 # Sunday (0) -> Friday
    date
  end

  # TODO: Move any testing methods to test/
  def create_test_event
    base_name = "Brexit Blues"

    sp = Spicy::Proton.new

    if params[:type] == 'Simple'
      date_start = Date.today
      date_end = Date.today
      location_setup = [%w[Bar REGULAR], %w[Floaters FLOATER]]
      job_setup = ['Bar Staff']
      n_prospects = 10
      n_prospects_spare = 10
    else
      date_start = Date.today
      date_end = Date.tomorrow
      location_setup = [%w[Bar REGULAR], %w[Entrance REGULAR], ["North-East Entrance", "REGULAR"], %w[Floaters FLOATER], %w[Spare SPARE]]
      job_setup = ['Greeter', 'Bouncer', 'Bar Staff']
      n_prospects = 100
      n_prospects_spare = 100
    end

    n = 1
    event_name = "#{base_name} #{n.to_s.rjust(3, '0')} (#{current_user.first_name})"
    while Event.find_by_name(event_name)
      event_name = "#{base_name} #{n.to_s.rjust(3, '0')} (#{current_user.first_name})"
      n = n + 1
    end

    event = Event.new
    event.name = event_name
    event.display_name = event_name
    event.category_id = EventCategory.first.id
    event.date_start = date_start
    event.date_end = date_end
    event.show_in_time_clocking_app = true
    event.show_in_payroll = true
    event.show_in_history = false
    event.show_in_public = false
    event.post_code = 'SW1A 0AA'
    event.site_manager = 'Bob'
    event.office_manager_id = current_user.id
    event.blurb_title = "A #{sp.adjective} Event!".titlecase
    event.blurb_subtitle = "A #{sp.adjective} and #{sp.adjective} Team!".titlecase
    event.blurb_opening = "Do you like #{sp.adjective} #{sp.noun.pluralize}, #{sp.adjective} #{sp.noun.pluralize}, #{sp.adjective} #{sp.noun.pluralize} and #{sp.adjective} #{sp.noun.pluralize}? If so, you'll #{sp.noun} this!"
    event.blurb_job = "The #{sp.adjective} jobs!"
    event.blurb_shift = "Work up to #{rand(0..24)} hours a day!"
    event.blurb_uniform = "Wear your most #{sp.adjective} clothes!"
    event.blurb_transport = "#{sp.adverb.capitalize} ride a #{sp.noun} to the event"
    event.leader_general = "You are a #{sp.noun}"
    event.leader_meeting_location = "Meet at the #{sp.adjective} #{sp.noun}"
    event.leader_meeting_location_coords = "51.499511, -0.124951"
    event.leader_job_role = "Look after the other #{sp.adjective} employees"
    event.leader_arrival_time = "Arrive before the #{sp.noun.pluralize} #{sp.verb} please"
    event.leader_energy = "#{sp.adjective.capitalize}, #{sp.adjective}, and #{sp.adjective}!"
    event.leader_uniform = "#{sp.adjective.capitalize} clothing please!"
    event.leader_handbooks = "Please read the #{sp.adjective} manual"
    event.leader_food = "Hope you like to eat #{sp.adjective} #{sp.noun}"
    event.leader_transport = "Get here on a #{sp.adjective} #{sp.noun}"
    event.leader_accomodation = "Sleep in the #{sp.adjective} #{sp.noun}"
    event.save!

    #######################
    ##### EVENT DATES #####
    #######################

    [date_start, date_end].uniq.each do |date|
      event_date = EventDate.new
      event_date.event_id = event.id
      event_date.date = date
      event_date.save!
    end

    ##################
    ##### CLIENT #####
    ##################

    client = Client.where(active: true, name: 'Flair Test').first_or_initialize
    client.save
    client_contact = ClientContact.where(client: client, first_name: 'Julie', last_name: 'Andrews', email: 'julie@andrews.com', mobile_no: '0123456789', active: true).first_or_initialize
    client_contact.save

    event_client = EventClient.new
    event_client.client = client
    event_client.event = event
    event_client.save!

    event.leader_client_contact_id = client_contact.id
    event.save!

    ##################
    ##### SHIFTS #####
    ##################

    [date_start, date_end].uniq.each do |date|
      shift = Shift.new
      shift.date = date
      shift.time_start = Time.utc(2000,1,1,8)
      shift.time_end = Time.utc(2000,1,1,17)
      shift.event = event
      shift.save!
    end

    #####################
    ##### LOCATIONS #####
    #####################
    location_setup.each do |name, type|
      location = Location.new
      location.name = name
      location.event = event
      location.type = type
      location.save!
    end

    ################
    ##### JOBS #####
    ################

    job_setup.each do |name|
      job = Job.new
      job.event = event
      job.name = name
      job.pay_17_and_under = 6
      job.pay_18_and_over = 7
      job.pay_21_and_over = 8
      job.pay_25_and_over = 9
      job.include_in_description = true
      job.public_name = name
      job.save!
    end

    #######################
    ##### ASSIGNMENTS #####
    #######################
    locations = Location.where(event: event)
    jobs = Job.where(event: event)
    shifts = Shift.where(event: event)

    assignments = []
    locations.where(type: 'REGULAR').each do |location|
      jobs.each do |job|
        shifts.each do |shift|
          assignment = Assignment.new
          assignment.event = event
          assignment.shift = shift
          assignment.job = job
          assignment.location = location
          assignment.staff_needed = rand(3..10)
          assignment.save!
          assignments << assignment
        end
      end
    end

    assignments_spare = []
    locations.where.not(type: 'REGULAR').each do |location|
      jobs.each do |job|
        shifts.each do |shift|
          assignment = Assignment.new
          assignment.event = event
          assignment.shift = shift
          assignment.job = job
          assignment.location = location
          assignment.staff_needed = rand(3..10)
          assignment.save!
          assignments_spare << assignment
        end
      end
    end

    ####################################
    ##### GIGS AND GIG_ASSIGNMENTS #####
    ####################################

    shuffled_prospects = Prospect.where(status: 'EMPLOYEE').where.not(photo: nil).shuffle
    prospects = shuffled_prospects.first(n_prospects)

    n_assignment = 0
    (0..n_prospects-1).each do |n_prospect|
      prospect = prospects[n_prospect]
      gig = Gig.where(event: event, prospect: prospect).first_or_create!
      gig_assignment = GigAssignment.new
      gig_assignment.gig = gig
      gig_assignment.assignment = assignments[n_assignment]
      gig_assignment.save!
      n_assignment = (n_assignment == assignments.length - 1) ? 0 : n_assignment + 1
    end

    prospects_spare = shuffled_prospects.last(n_prospects_spare)

    n_assignment = 0
    (0..n_prospects_spare-1).each do |n_prospect|
      prospect = prospects_spare[n_prospect]
      gig = Gig.where(event: event, prospect: prospect).first_or_create!
      gig_assignment = GigAssignment.new
      gig_assignment.gig = gig
      gig_assignment.assignment = assignments_spare[n_assignment]
      gig_assignment.save!
      n_assignment = (n_assignment == assignments_spare.length - 1) ? 0 : n_assignment + 1
    end

    ########################
    ##### TEAM LEADERS #####
    ########################

    team_leader_role = TeamLeaderRole.new
    team_leader_role.event = event
    team_leader_role.user_id = current_user.id
    team_leader_role.user_type = "Officer"
    team_leader_role.enabled = true
    team_leader_role.save!

    data = {}
    data[:message] = "Event '#{event.name}' Created!"
    render json: OfficeZoneSync.get_synced_response(data)
  end

# NAME:        upload_event_photo
# DESCRIPTION: Upload a photo for an event
  def upload_event_photo
    uploaded  = params[:file_upload]
    @event    = Event.find(params[:id])
    directory = File.join(Flair::Application.config.shared_dir, 'public', 'event_photos')
    result    = handle_image_upload(uploaded, directory, @event.id.to_s, Event::EVENT_THUMBNAIL_SIZE)

    case result
    when :ok
      @event.photo = "#{@event.id}.#{FileUploads::FILE_FORMAT}"
      @event.save
      render json: OfficeZoneSync.get_synced_response
    when :thumbnail_failed
      render json: {status: "error", message: "A server error occurred while processing #{uploaded.original_filename}. The file may be corrupted. If this happens every time you try to upload this file, please contact the site developers for help."}
    when :not_enough_space
      render json: {status: "error", message: "Sorry, there is not enough free space on the server's hard drive"}
    when :too_large
      render json: {status: "error", message: "Photo files cannot be larger than 20 megabytes"}
    when :unknown_image_type
      render json: {status: "error", message: "Photos must be .jpg, .jpeg, .gif, or .png files."}
    else
      render json: {status: "error", message: "An unknown error occured while uploading the event photo"}
    end
  end

  # NAME:        upload_bulk_interview_photo
  # DESCRIPTION: Upload a photo for an interview
  def upload_bulk_interview_photo
    uploaded  = params[:file_upload]
    @bulk_interview    = BulkInterview.find(params[:id])
    directory = File.join(Flair::Application.config.shared_dir, 'public', 'bulk_interview_photos')
    result    = handle_image_upload(uploaded, directory, @bulk_interview.id.to_s, BulkInterview::THUMBNAIL_SIZE)

    case result
      when :ok
        @bulk_interview.photo = "#{@bulk_interview.id}.#{FileUploads::FILE_FORMAT}"
        @bulk_interview.save
        render json: OfficeZoneSync.get_synced_response
      when :thumbnail_failed
        render json: {status: "error", message: "A server error occurred while processing #{uploaded.original_filename}. The file may be corrupted. If this happens every time you try to upload this file, please contact the site developers for help."}
      when :not_enough_space
        render json: {status: "error", message: "Sorry, there is not enough free space on the server's hard drive"}
      when :too_large
        render json: {status: "error", message: "Photo files cannot be larger than 20 megabytes"}
      when :unknown_image_type
        render json: {status: "error", message: "Photos must be .jpg, .jpeg, .gif, or .png files."}
      else
        render json: {status: "error", message: "An unknown error occured while uploading the event photo"}
    end
  end

  # NAME:        upload_content_thumbnail
  # DESCRIPTION: Upload a thumbnail for an text block
  def upload_content_thumbnail
    uploaded = params[:file_upload]
    text_block = TextBlock.find(params[:id])
    directory = File.join(Flair::Application.config.shared_dir, 'public', 'content_thumbnails')
    result    = handle_image_upload(uploaded, directory, text_block.id.to_s, TextBlock::THUMBNAIL_SIZE)

    case result
      when :ok
        text_block.thumbnail = "#{text_block.id}.#{FileUploads::FILE_FORMAT}"
        text_block.save
        render json: OfficeZoneSync.get_synced_response
      when :thumbnail_failed
        render json: {status: "error", message: "A server error occurred while processing #{uploaded.original_filename}. The file may be corrupted. If this happens every time you try to upload this file, please contact the site developers for help."}
      when :not_enough_space
        render json: {status: "error", message: "Sorry, there is not enough free space on the server's hard drive"}
      when :too_large
        render json: {status: "error", message: "Photo files cannot be larger than 20 megabytes"}
      when :unknown_image_type
        render json: {status: "error", message: "Photos must be .jpg, .jpeg, .gif, or .png files."}
      else
        render json: {status: "error", message: "An unknown error occured while uploading the event photo"}
    end
  end

  ##### This is used by the 'assigner' dialogs in the office zone
  def add_remove_gigs
    response = {}
    if params[:events_add]
      params[:events] = params[:events_add]
      ##### Creating gigs "virtually deletes" a gig request, which won't be processed by OfficeZoneSync,
      ##### So we send it manually
      response = create_gigs_internal
    end

    if params[:events_remove]
      gig_ids = []
      params[:events_remove].each do |id|
        if gig = Gig.where(prospect_id: params[:prospect], event_id: id).first
          gig_ids << gig.id
        end
      end
      params[:ids] = gig_ids
      params[:delete_gig_requests] = true
      delete_gigs_internal
    end

    render json: OfficeZoneSync.get_synced_response(response)
  end

# NAME:        create_gig
# DESCRIPTION: Create a new Gig, and mark matching Gig Request as 'hired'
  def create_gig
    params[:gig_requests] = [params[:id]]
    create_gigs
  end
  def create_gigs
    response = create_gigs_internal
    render json: OfficeZoneSync.get_synced_response(response)
  end
  def create_gigs_internal
    deleted_gig_request_ids = []
    gigs = if params[:gig_requests].present?
      GigRequest.includes(:prospect, :event, :job).where(id: params[:gig_requests]).update(spare: false)
      params[:gig_requests].each do |gr_id|
        gig_request = GigRequest.find_by_id(gr_id)
        deleted_gig_request_ids << gr_id if !gig_request || gig_request.gig_id
      end
      gig_requests = GigRequest.where(id: params[:gig_requests])
      gig_requests.map do |gr|
        event = Event.find(gr.event_id)
        [
          gr,
          Gig.where(prospect_id: gr.prospect_id, event: event, job_id: gr.job_id, location_id: event.default_location_id).first_or_initialize
        ]
      end
    elsif params[:prospect].present? && params[:events].present?
      prospect_id = params[:prospect].to_i
      gig_requests = GigRequest.where(prospect_id: prospect_id, event_id: params[:events])
      params[:events].map do |event_id|
        event = Event.find(event_id)
        event_id = event_id.to_i
        [
          gig_requests.find { |gr| gr.event_id == event_id && gr.prospect_id == prospect_id },
          Gig.where(prospect_id: prospect_id, event: event, job_id: event.default_job_id, location_id: event.default_location_id).first_or_initialize
        ]
      end
    elsif params[:event].present? && params[:prospects].present?
      event_id = params[:event].to_i
      event = Event.find(event_id)
      gig_requests = GigRequest.where(prospect_id: params[:prospects], event_id: event_id)
      params[:prospects].map do |prospect_id|
        prospect_id = prospect_id.to_i
        [
          gig_requests.find { |gr| gr.event_id == event_id && gr.prospect_id == prospect_id },
          Gig.where(prospect_id: prospect_id, event: event, job_id: event.default_job_id, location_id: event.default_location_id).first_or_initialize
        ]
      end
    else
      raise "Help! Didn't receive expected params!"
    end

    if current_user.staffer? && gigs.any? { |(gr,g)| g.event.closed? }
      render json: {status: 'error', message: 'Only managers can edit gigs for closed events.'}
      return
    end

    # filter out: 1) Already Hired Requests, 2) Pending Requests, 3) Already Created Gigs (in case of no requests)
    gigs = gigs.reject { |(gr,g)| gr && (gr.gig_id || gr.spare) || g.id }

    # 'good' are the GigRequests/Gigs which pass validation and can be saved
    good = gigs.select { |(gr,g)| g.valid? && (gr.nil? || gr.valid?) }

    if good.present?
      gigs_for_prospect = good.map { |(gr,g)| g }.group_by(&:prospect_id)
      prospects = Prospect.where(id: gigs_for_prospect.keys)

      prospects.each do |prospect|
        if prospect.applicant?
          unless prospect.validate_mandatory_office_fields
            error_messages = prospect.errors.full_messages.to_sentence
            return { message: error_messages }
          end
          hire_applicant(prospect)
          # let the applicant know they've been hired on for their first gig
          send_mail(StaffMailer.applicant_accepted(prospect))
        elsif prospect.sleeper?
          prospect.status = 'EMPLOYEE'
        else
          event_ids = Event.where(id: gigs_for_prospect[prospect.id].pluck(:event_id), send_scheduled_to_work_auto_email: true).pluck(:id)
          queue_notification('accepted', prospect, event_ids: event_ids) if event_ids.length > 0
        end
        prospect.save
      end

      good.each do |(gr,gig)|
        gig.save
        if gr
          gr.gig_id = gig.id
          gr.save
        end
        if gig.event.default_assignment_id
          gig_assignment = GigAssignment.new(gig_id: gig.id, assignment_id: gig.event.default_assignment_id)
          gig_assignment.save
        end
      end

      # note that while we tell the client the GigRequest was 'deleted', it is actually retained in our DB, marked as 'hired'
      # the 'schema' used for data on the client is not entirely the same as what is stored on the server
      # the 'gig requests' which are sent to the client are *only* those which are *not* hired
      # so from the client's point of view, when a GigRequest is marked as 'hired', it is effectively 'deleted'
      good.each do |gr,g|
        if gr
          if params[:gig_requests].present?
            g.notes = gr.notes
            g.save
          end
          Deletion.create!(table: 'gig_requests', record_id: gr.id)
          deleted_gig_request_ids << gr.id
        end
      end
    end
    { deleted: {gig_requests: deleted_gig_request_ids}}
  end

  def hire
    applicant = Prospect.find(params[:id])

    unless applicant.validate_mandatory_office_fields
      error_messages = applicant.errors.full_messages.to_sentence
      return render json: OfficeZoneSync.get_synced_response({message: error_messages})
    end

    hire_applicant(applicant)
    send_mail(StaffMailer.applicant_accepted(applicant))
    render json: OfficeZoneSync.get_synced_response
  end

  def status_validate
    applicant = Prospect.find(params[:id])

    if params[:status] == 'EMPLOYEE' && applicant.status == 'APPLICANT'
      applicant.assign_attributes(prospect_params(params[:prospect]))
      unless applicant.validate_mandatory_office_fields
        error_messages = applicant.errors.full_messages.to_sentence
        return render json: OfficeZoneSync.get_synced_response({message: error_messages})
      end
    end
    
    render json: OfficeZoneSync.get_synced_response
  end

  private

  def hire_applicant(applicant)
    applicant.status = 'EMPLOYEE'
    applicant.applicant_status = nil
    applicant.notes = ''
    applicant.save
  end

  public

# NAME:        delete_gig
# DESCRIPTION: Delete a Gig, and mark the matching Gig Request as 'not hired'
  def delete_gig
    params[:ids] = [params[:id]]
    delete_gigs
  end
  def delete_gigs
    delete_gigs_internal
    render json: OfficeZoneSync.get_synced_response
  end
  def delete_gigs_internal
    gigs = Gig.includes(:timesheet_entries).where(id: params[:ids])
    if current_user.staffer? && gigs.any? { |g| g.event.closed? }
      render json: {status: 'error', message: 'Only managers can edit gigs for closed events.'}
      return
    end

    standard_replies = ['Cancelled', 'Cancelled Within 18 Hours of the Event', 'Fully Staffed', 'No Bar Experience', 'No Confirmation of Interest', 'No Confirmation - Gentle', 'No ID as Required', 'No Show', 'Poor Performance', 'Reduction of Staffing Numbers', 'Travel Distance', 'Unsuccessful Work Request', 'Unsuitable for this Event', 'Event ‘Spare’ Status']
    gigs.each do |gig|
      action_log_reason = params[:lognote]
      if (params[:lognote].present? || params[:reason].present?) && gig.prospect != 'APPLICANT'
        if !(standard_replies.include?(params[:lognote].to_s))
          notes = gig.prospect.notes || ''
          notes << "\n\n" unless notes.empty?
          notes << "\n\n" unless notes.empty?
          notes << "REMOVED from #{gig.event.name} (#{gig.event.date_start.to_print}) for this reason: "
          notes << params[:lognote] if params[:lognote].present?
          notes << ". " if params[:lognote].present? && params[:reason].present?
          notes << params[:reason] if params[:reason].present?
          gig.prospect.update_column(:notes, notes)
          action_log_reason = 'Manual Reason'
        end

        action = 'Removed'
        if params[:delete_gig_requests]
          action = 'Deleted'
        end
        action_taken = ActionTaken.new(action: action, reason: action_log_reason, event_id: gig.event_id, prospect_id: gig.prospect.id)
        action_taken.save
        update_no_of_contracts(gig.prospect, params[:lognote])
      end

      if params[:delete_gig_requests]
        if (gig_request = gig.request)
          gig_request.destroy
        end
      else
        gig_request = GigRequest.where(prospect_id: gig.prospect.id, event_id: gig.event.id).first_or_initialize
        gig_request.gig_id = nil
        gig_request.spare = true
        gig_request.job_id ||= gig.job_id
        gig_request.job_id ||= Event.find_by(id: gig.event.id).default_job_id
        
        if gig_request.job_id.present?
          gig_request.save
        end
      end

      add_flag_photo(gig.prospect) if ['Cancelled Within 18 Hours of the Event', 'No Show'].include?(params[:lognote].to_s)

      gig.destroy
    end

    if params[:send_email]
      gigs.group_by(&:prospect_id).each do |prospect_id, prospect_gigs|
        queue_notification('removed', Prospect.find(prospect_id), event_ids: prospect_gigs.map(&:event_id), reason: params[:reason])
      end
    end
  end
  def add_flag_photo(prospect)
    action_taken = prospect.action_takens.order(:id).last
    prospect.flag_photo = if action_taken.reason == 'No Show'
                            "<div > <img class='name-column-flag' src='/flag_photo/red' > </div>"
                          else
                            if prospect.flag_photo == "<div > <img class='name-column-flag' src='/flag_photo/red' > </div>"
                              "<div > <img class='name-column-flag' src='/flag_photo/red' > </div>"
                            else
                              "<div > <img class='name-column-flag' src='/flag_photo/amber' width='24px' height='24px'> </div>"
                            end
                          end
    prospect.save
  end

# NAME:        update_gigs
# DESCRIPTION: Update details for a set of Gigs
  def update_gigs
    messages = []

    gigs = Gig.includes(:event, :gig_assignments).where(id: OfficeZoneSync.reject_deleted(Gig, params[:gigs].keys))

    gigs.each do |gig|
      attrs = params[:gigs][gig.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      attrs[:miscellaneous_boolean] ||= false  # HTML checkboxes don't submit anything if not checked
      attrs.delete :published # We aren't updating this, its read only
      ##### Pull out parameters for GigTaxWeek
      confirmed = attrs.delete(:confirmed) || false # HTML checkboxes don't submit anything if not checked
      tax_week_id = attrs.delete(:tax_week_id)

      ##### Pull out parameters for GigAssignment
      selected_assignment_ids = attrs[:assignment_ids] && attrs.delete(:assignment_ids).map { |id| id.to_i } || []
      selected_tag_ids = attrs[:tag_ids] && attrs.delete(:tag_ids).map { |id| id.to_i } || []
      all_filtered_assignment_ids = attrs[:all_filtered_assignment_ids] && attrs.delete(:all_filtered_assignment_ids).map { |id| id.to_i } || []

      gig.assign_attributes(gig_params(attrs))
      render_update_gig_for_staffer_if(gig.event.closed? && ((gig.changed_attributes.keys - ['miscellaneous_boolean']).length > 0)); return if performed?

      if gig.save
        if tax_week_id
          # Sometimes there's a race condition in activerecord, which causes it to try and create an entry that already
          # exists. In that case, catch the error and retry.
          begin
            gig_tax_week = GigTaxWeek.where(tax_week_id: tax_week_id, gig_id: gig.id).first_or_create
          rescue ActiveRecord::RecordNotUnique
            retry
          end
          gig_tax_week.confirmed = confirmed
          render_update_gig_for_staffer_if(gig.event.closed? && ((gig_tax_week.changed_attributes.keys - ['confirmed']).length > 0)); return if performed?
          gig_tax_week.save
        end
        ##### Create/Destroy any added/removed assignments
        existing_assignment_ids = gig.gig_assignments.pluck(:assignment_id).select { |id| all_filtered_assignment_ids.include? id }
        removed_assignment_ids = existing_assignment_ids - selected_assignment_ids
        removed_gig_assignment_ids = gig.gig_assignments.select { |ga| removed_assignment_ids.include? ga.assignment_id}.pluck(:id)
        render_update_gig_for_staffer_if(gig.event.closed? && removed_gig_assignment_ids.length > 0); return if performed?
        GigAssignment.includes(:timesheet_entry).where(id: removed_gig_assignment_ids).each do |gig_assignment|
          if (timesheet_entry = gig_assignment.timesheet_entry) && timesheet_entry.status == 'NEW'
            timesheet_entry.destroy
            gig_assignment.reload #Reload so that the timesheet entry deletion is seen
          end
          gig_assignment.destroy
        end

        new_assignment_ids = selected_assignment_ids - existing_assignment_ids
        render_update_gig_for_staffer_if(gig.event.closed? && new_assignment_ids.length > 0); return if performed?

        new_assignment_ids.each do |new_assignment_id|
          tax_week_id = Assignment.find(new_assignment_id).shift.tax_week_id
          timesheet_entries = TimesheetEntry.where(gig_assignment_id: GigAssignment.where(gig_id: gig.event.gigs.pluck(:id)).pluck(:id), tax_week_id: tax_week_id)
          # Sometimes there's a race condition in activerecord, which causes it to try and create an entry that already
          # exists. In that case, catch the error and retry.
          begin
            # A block provided to first_or_create will be executed only if a new instance is being created. The block is NOT executed on an existing record.
            GigAssignment.where(gig_id: gig.id, assignment_id: new_assignment_id).first_or_create do |gig_assignment|
              gig_assignment.save
              if timesheet_entries.length > 0
                status = timesheet_entries.any? { |tse| tse.status == "NEW"} ? "NEW" : "PENDING"
                timesheet_entry = TimesheetEntry.new(gig_assignment_id: gig_assignment.id, tax_week_id: tax_week_id, status: status, time_start: gig_assignment.shift.time_start)
                timesheet_entry.save
              end
            end
          rescue ActiveRecord::RecordNotUnique
            retry
          end
        end

        # If an assignment was added/removed, we set the gig.published to false. This will indicate that a webapp data export should be performed by the user.
        gig.update(published: false) if removed_assignment_ids.present? or removed_gig_assignment_ids.present? or new_assignment_ids.present?

        ##### Create/Destroy and added/removed tags
        existing_tag_ids = GigTag.where(gig_id: gig.id).pluck(:tag_id)
        tag_ids_to_remove = existing_tag_ids - selected_tag_ids
        render_update_gig_for_staffer_if(gig.event.closed? && tag_ids_to_remove.length > 0); return if performed?
        GigTag.where(gig_id: gig.id, tag_id: tag_ids_to_remove).destroy_all

        tag_ids_to_add = selected_tag_ids - existing_tag_ids
        render_update_gig_for_staffer_if(gig.event.closed? && tag_ids_to_add.length > 0); return if performed?
        tag_ids_to_add.each { |new_tag_id| GigTag.where({gig_id: gig.id, tag_id: new_tag_id}).first_or_create }
      end
    end

    unless params[:prospects].nil?
      prospects = Prospect.find(params[:prospects].keys)
      prospects.each do |prospect|
        attrs = params[:prospects][prospect.id.to_s]
        attrs[:left_voice_message] ||= false
        prospect.assign_attributes(prospect_params(attrs))
        prospect.save
      end
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def render_update_gig_for_staffer_if(condition)
    if current_user.staffer? && condition
      render json: {status: 'error', message: 'Staffers can only edit Call/Misc for gigs on closed events.'}
    end
  end

  def clear_confirmed_on_gigs
    if !params[:tax_week_id].empty?
      GigTaxWeek.includes(:tax_week, gig: [:prospect, :event]).where(gig_id: params[:gig_ids], tax_week_id: params[:tax_week_id], confirmed: true).each do |gig_tax_week|
        gig_tax_week.confirmed = false
        gig_tax_week.save
      end
      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: 'error', message: 'Must select a tax week.'}
    end
  end

  def clear_misc_flag
    Gig.includes(:prospect).where(id: params[:ids]).select { |gig| gig.miscellaneous_boolean }.each do |gig|
      gig.miscellaneous_boolean = false
      gig.save
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def update_gig_requests
    requests = GigRequest.find(OfficeZoneSync.reject_deleted(GigRequest, params[:gig_requests].keys))
    requests.each do |request|
      attrs = params[:gig_requests][request.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      attrs[:notes] ||= ''
      request.update(gig_request_params(attrs))
      request.reload
      if request.gig_id != nil
        request.gig.notes = request.notes
        request.gig.save
      end
      request.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def set_spare
    data = {}
    request = GigRequest.find_by_id(params[:id])
    if request && !(request.gig_id)
      request.spare = (params[:spare] == 'true')
      request.save
      prospect = request.prospect
      if params[:spare] == 'true'
        if prospect.held_spare_contracts.nil?
          prospect.held_spare_contracts = 1
        else
          prospect.held_spare_contracts = prospect.held_spare_contracts + 1
        end
      else
        if prospect.held_spare_contracts == 1
          prospect.held_spare_contracts = nil
        else
          prospect.held_spare_contracts = prospect.held_spare_contracts - 1 unless prospect.held_spare_contracts.nil?
        end
      end
      prospect.save
    else
      data[:deleted] = {gig_requests: [params[:id]]}
      if request then
        data[:message] = "This Request was already Hired"
      else
        data[:message] = "This Request was already Deleted"
      end
    end
    render json: OfficeZoneSync.get_synced_response(data)
  end

  def bulk_info_of_applicants
    applicants = Prospect.where(id: params[:prospect_ids])
    applicants.where.not(applicant_status: 'UNCONFIRMED').each do |applicant|
      applicant.email_status = params[:email_status] if params[:email_status].present?
      applicant.headquarter = params[:headquarter]
      applicant.missed_interview_date = params[:missed_interview_date] if params[:missed_interview_date].present?
      applicant.texted_date = params[:texted_date] if params[:texted_date].present?
      applicant.left_voice_message = params[:left_voice_message] if params[:left_voice_message].present?
      applicant.save
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_gig_requests
    requests = GigRequest.where(id: params[:gig_requests])
    deleted_gig_request_ids = []
    params[:gig_requests].each do |gr_id|
      gig_request = GigRequest.find_by_id(gr_id)
      deleted_gig_request_ids << gr_id if !gig_request || gig_request.gig_id
    end
    # can't reject gig requests which are already hired, or which are 'spare'
    requests = requests.where('gig_id IS NULL')

    standard_replies = ['Cancelled', 'Cancelled Within 18 Hours of the Event', 'Fully Staffed', 'No Bar Experience', 'No Confirmation of Interest', 'No Confirmation - Gentle', 'No ID as Required', 'No Show', 'Poor Performance', 'Reduction of Staffing Numbers', 'Travel Distance', 'Unsuccessful Work Request', 'Unsuitable for this Event', 'Event ‘Spare’ Status']
    requests.group_by(&:prospect_id).each do |prospect_id,requests|
      prospect = Prospect.find(prospect_id)
      if (params[:lognote].present? || params[:reason].present?) && !(standard_replies.include?(params[:lognote].to_s)) && prospect.status != 'APPLICANT'
        notes = prospect.notes || ''
        notes << "\n\n" unless notes.empty?
        notes << "DECLINED for #{requests.map { |rq| rq.event.name }.to_sentence} for this reason: "
        notes << params[:lognote] if params[:lognote].present?
        notes << ". " if params[:lognote].present? && params[:reason].present?
        notes << params[:reason] if params[:reason].present?
        prospect.notes = notes
        prospect.save
      end

      if params[:send_email]
        queue_notification('rejected', prospect, event_ids: requests.map(&:event_id), reason: params[:reason])
      end
    end

    requests.each do |request|
      reject_event = RejectEvent.new(prospect_id: request.prospect_id, event_id: request.event_id, job_id: request.job_id)
      prospect = Prospect.find(request.prospect_id)
      # if prospect.status == "APPLICANT"
      #   reject_event.has_seen = true
      # end
      reject_event.save
      if params[:lognote].present?
        prospect_action_reason = params[:lognote].to_s
        if !(standard_replies.include?(prospect_action_reason))
          prospect_action_reason = 'Manual Reason'
        end
        action_taken = ActionTaken.new(action: 'Declined', reason: prospect_action_reason, event_id: request.event_id, prospect_id: request.prospect_id)
        action_taken.save
        update_no_of_contracts(request.prospect, params[:lognote])
        add_flag_photo(request.prospect) if ['Cancelled Within 18 Hours of the Event', 'No Show'].include?(params[:lognote].to_s)
      end
    end

    requests.destroy_all
    render json: OfficeZoneSync.get_synced_response({deleted: {gig_requests: deleted_gig_request_ids}})
  end
  def update_no_of_contracts(prospect , reason)
    if reason == 'Cancelled'
      if prospect.cancelled_contracts.nil?
        prospect.cancelled_contracts = 1
      else
        prospect.cancelled_contracts = prospect.cancelled_contracts + 1
      end
    end
    if reason == 'Cancelled Within 18 Hours of the Event'
      if prospect.cancelled_eighteen_hrs_contracts.nil?
        prospect.cancelled_eighteen_hrs_contracts = 1
      else
        prospect.cancelled_eighteen_hrs_contracts = prospect.cancelled_eighteen_hrs_contracts + 1
      end
    end
    if reason == 'No Show'
      if prospect.no_show_contracts.nil?
        prospect.no_show_contracts = 1
      else
        prospect.no_show_contracts = prospect.no_show_contracts + 1
      end
    end
    if reason == 'No Confirmation of Interest' || reason == 'No Confirmation - Gentle'
      if prospect.non_confirmed_contracts.nil?
        prospect.non_confirmed_contracts = 1
      else
        prospect.non_confirmed_contracts = prospect.non_confirmed_contracts + 1
      end
    end
    prospect.save
  end

  def create_content
    block = TextBlock.new(text_block_params(params[:content]))
    if block.type == 'terms' && block.save
      db.execute("UPDATE prospects SET datetime_agreement = NULL WHERE datetime_agreement IS NOT NULL;")
      render json: OfficeZoneSync.get_synced_response({message: "Saved! Note that all employees will have to agree to the new terms before applying to work at more events."})
    else
      render json: OfficeZoneSync.get_synced_response
    end
  end

# NAME:        update_content
# DESCRIPTION: Save updates to admin-editable content
  def update_content
    block = TextBlock.find(params[:id])
    block.assign_attributes(text_block_params(params[:content]))
    if block.type_changed?
      render json: {status: "error", message: "Can't change Content item type"}
    elsif block.type == 'terms'
      params[:content][:type] = 'terms'
      TextBlock.new(text_block_params(params[:content]))
      render json: OfficeZoneSync.get_synced_response
    elsif block.type == 'page' && block.key_changed?
      render json: {status: "error", message: "Can't change names of Page Templates"}
    else
      block.save
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def delete_content
    render_if_nonexistent(TextBlock, params[:id], nil); return if performed?

    text_block = TextBlock.find(params[:id])
    if text_block.type == 'email' || text_block.type == 'news'
      text_block.destroy
      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: "error", message: "You can only delete E-mail templates or News items"}
    end
  end

  def create_faq_entry
    faq_entry = FaqEntry.new
    faq_entry.update(faq_entry_params(params[:faq_entry]))
    render json: OfficeZoneSync.get_synced_response
  end

  def update_faq_entry
    faq_entry = FaqEntry.find(params[:id])
    faq_entry.update(faq_entry_params(params[:faq_entry]))
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_faq_entry
    render_if_nonexistent(FaqEntry, params[:id], nil); return if performed?

    faq_entry = FaqEntry.find(params[:id])
    faq_entry.destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def create_officer
    if !current_user.manager?
      render status: :forbidden, body: nil
      return
    elsif !current_user.admin? && params[:officer][:role] == 'admin'
      render json: {status: "error", message: "You are not authorized to create new admin accounts"}
      return
    elsif params[:password].blank?
      render json: {status: "error", message: "Password is blank", bad_fields: ["password"]}
      return
    end

    officer = Officer.new
    officer.assign_attributes(officer_params(params[:officer]))
    if officer.save
      account = Account.new
      account.confirmed_email = true
      account.password = params[:password]
      account.user_id = officer.id
      account.user_type = "Officer"
      if account.save
        officer.account = account
        unless officer.save
          account.destroy
          officer.destroy
        end
      else
        officer.destroy
      end
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def update_officer
    officer = Officer.find(params[:id])

    if !current_user.manager?
      render status: :forbidden, body: nil
      return
    elsif officer.admin? && params[:officer][:role] != 'admin'
      render json: {status: "error", message: "You cannot reduce the access level of an administrator account"}
      return
    elsif !current_user.admin? && params[:officer][:role] == 'admin'
      render json: {status: "error", message: "You are not authorized to create new admin accounts"}
      return
    end

    if params[:password].present? && officer.id == current_user.id
      if Account.password_valid?(params[:password])
        officer.account.password = params[:password]
        officer.account.save!
      else
        render json: {status: "error", message: Account.why_invalid?(params[:password])}
        return
      end
    end

    officer.update(officer_params(params[:officer]))
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_officer
    render_if_nonexistent(Officer, params[:id], nil); return if performed?

    officer = Officer.find(params[:id])

    if !current_user.manager?
      render status: :forbidden, body: nil
    elsif officer.admin? && !current_user.admin?
      render json: {status: "error", message: "You cannot delete an administrator account"}
    elsif officer.id == current_user.id
      render json: {status: "error", message: "You cannot delete your own account"}
    else
      officer.destroy
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def lock_officer
    officer = Officer.find(params[:id])

    if !current_user.manager?
      render status: :forbidden, body: nil
    elsif officer.admin? && !current_user.admin?
      render json: {status: "error", message: "You cannot lock an administrator account"}
    elsif officer.id == current_user.id
      render json: {status: "error", message: "You cannot lock your own account"}
    else
      officer.account.locked = true
      officer.account.save
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def unlock_officer
    officer = Officer.find(params[:id])

    if !current_user.manager?
      render status: :forbidden, body: nil
    elsif officer.id == current_user.id
      render json: {status: "error", message: "You cannot unlock your own account"}
    else
      officer.account.locked = false
      officer.account.save
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def create_library_item
    item = LibraryItem.new(name: params[:library_item][:name], filename: params[:file_upload].original_filename)

    if item.valid?
      uploaded  = params[:file_upload]
      directory = File.join(Flair::Application.config.shared_dir, 'library')
      result    = handle_file_upload(uploaded, directory)

      case result
      when :ok
        item.save
        render json: OfficeZoneSync.get_synced_response
      when :not_enough_space
        render json: {status: "error", message: "Sorry, there is not enough free space on the server's hard drive"}
      else
        raise 'Help!'
      end
    else
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def update_library_item
    item = LibraryItem.find(params[:id])
    params[:library_item].delete(:filename) # can't be changed once uploaded
    item.update(library_item_params(params[:library_item]))
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_library_item
    render_if_nonexistent(LibraryItem, params[:id], nil); return if performed?

    item = LibraryItem.find(params[:id])
    path = File.join(Flair::Application.config.shared_dir, 'library', item.filename)
    `rm #{path}`
    item.destroy
    render json: OfficeZoneSync.get_synced_response
  end

# NAME:        download_library_file
# DESCRIPTION:
  def download_library_file
    item = LibraryItem.find(params[:id])
    send_file(File.join(Flair::Application.config.shared_dir, 'library', item.filename), filename: item.filename)
  end

  def update_expenses
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Expenses for a closed or cancelled Event"}
      return
    end

    if (new_record = params[:expenses].delete("-1"))
      new_expense = Expense.new(event_id: params[:event_id], name: new_record[:name], cost: new_record[:cost], notes: new_record[:notes])
      new_expense.save
    end

    expenses = Expense.find(params[:expenses].keys)
    expenses.each do |expense|
      attrs = params[:expenses][expense.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      expense.assign_attributes(expense_params(attrs))
      expense.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_expense
    render_if_nonexistent(Expense, params[:id], nil); return if performed?
    Expense.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_event_task
    render_if_nonexistent(EventTask, params[:id], nil); return if performed?
    EventTask.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_feature_jobs
    event = Event.find(params[:event_id])
    featured_job_id = params[:job_id]

    if params[:checked] == 'false'
      event.update(featured_job: nil)
    else
      event.update(featured_job: featured_job_id)
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def update_public_jobs
    job = Job.find(params[:job_id])
    job.update(include_in_description: params[:checked])

    render json: OfficeZoneSync.get_synced_response
  end

  # NAME:        update_jobs
  # DESCRIPTION: Save Jobs for an Event. Jobs to be saved may include up to 1 new one
  def update_jobs
    event = Event.find(params[:event_id])
    # Ordinary office staff can't edit details for Closed events
    # Managers and admins can
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Jobs for a closed or cancelled Event"}
      return
    end

    if (new_record = params[:jobs]&.delete("-1"))
      new_record[:event_id] = params[:event_id]
      new_job = Job.new(job_params(new_record))
      if new_job.number_of_positions == nil
        new_job.number_of_positions = 0
      end
      new_job.save
    end

    if params[:jobs]
      jobs = Job.find(params[:jobs]&.keys)

      featured_job_id = nil

      jobs.each do |job|
        attrs = params[:jobs][job.id.to_s]

        # if attrs[:featured_job]
        #   featured_job_id = job.id
        # end

        attrs = attrs.except(:featured_job)

        attrs[:include_in_description] ||= false

        attrs.each { |k, v| attrs[k] = nil if v == "" }
        attrs[:number_of_positions] = attrs[:number_of_positions] == "" || attrs[:number_of_positions] == nil ? 0 : attrs[:number_of_positions]
        job.update(job_params(attrs))
        job.update(updated_at: Time.now)
        if job.save
          PayWeek.includes(:prospect, :tax_week).where(status: %w(NEW PENDING), job: job).each do |pay_week|
            pay_week.rate = job.rate_for_person(pay_week.prospect, pay_week.tax_week.date_end)
            pay_week.save
          end
        end
      end
    end

    event.update(updated_at: Time.now)
    # event.update(featured_job: featured_job_id)

    render json: OfficeZoneSync.get_synced_response
  end

# NAME:        delete_job
# DESCRIPTION: Remove a Job (if it does not have any Gigs yet)
  def delete_job
    render_if_nonexistent(Job, params[:id], nil); return if performed?
    Job.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_shifts
    event = Event.find(params[:event_id])

    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: 'error', message: "You can't edit Shifts for a closed or cancelled Event"}
      return
    end

    if (new_record = params[:shifts].delete("-1"))
      new_shift = Shift.new(shift_params(new_record.merge(event_id: event.id)))
      new_shift.save
    end

    shifts = Shift.find(params[:shifts].keys)
    shifts.each do |shift|
      attrs = params[:shifts][shift.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      shift.assign_attributes(shift_params(attrs))
      shift.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_shift
    render_if_nonexistent(Shift, params[:id], nil); return if performed?
    Shift.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_locations
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Locations for a closed or cancelled Event"}
      return
    end

    if (new_record = params[:locations].delete("-1"))
      new_location = Location.new(event_id: params[:event_id], name: new_record[:name], type: new_record[:type])
      new_location.save
    end

    locations = Location.find(params[:locations].keys)
    locations.each do |location|
      attrs = params[:locations][location.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      location.assign_attributes(location_params(attrs))
      location.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_location
    render_if_nonexistent(Location, params[:id], nil); return if performed?
    Location.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_assignments
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Locations for a closed or cancelled Event"}
      return
    end

    if (new_params = params[:assignments].delete("-1"))
      new_assignment = Assignment.new(event_id: event.id, job_id: new_params[:job_id], shift_id: new_params[:shift_id], location_id: new_params[:location_id], staff_needed: new_params[:staff_needed])
      new_assignment.save
    end

    assignments = Assignment.find(params[:assignments].keys)
    assignments.each do |assignment|
      attrs = params[:assignments][assignment.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      assignment.assign_attributes(assignment_params(attrs))
      assignment.save
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def duplicate_assignments_daily
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Locations for a closed or cancelled Event"}
      return
    end

    source_date = Date.parse(params[:source_date])
    if params[:target_dates]
      params[:target_dates].each do |key, target_date_string|
        target_date = Date.parse(target_date_string)
        shift_ids = Shift.where(event_id: event.id, date: source_date).pluck(:id)
        assignments = Assignment.includes(:shift).where(shift_id: shift_ids)
        duplicate_assignments_to_other_days(assignments, (target_date - source_date).days)
      end
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def duplicate_assignments_weekly
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Locations for a closed or cancelled Event"}
      return
    end

    target_tax_week_ids = params[:target_tax_week_ids]
    source_tax_week = TaxWeek.find(params[:source_tax_week_id])
    if target_tax_week_ids
      target_tax_week_ids.each do |target_tax_week_id|
        target_tax_week = TaxWeek.find(target_tax_week_id)
        shift_ids = Shift.where(event_id: event.id, tax_week_id: source_tax_week.id).pluck(:id)
        assignments = Assignment.includes(:shift).where(shift_id: shift_ids)
        duplicate_assignments_to_other_days(assignments, (target_tax_week.date_start - source_tax_week.date_start).days)
      end
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def duplicate_assignments_to_other_days(assignments, days_offset)
    created = false
    assignments.each do |assignment|
      shift = assignment.shift
      new_shift = Shift.where(time_start: shift.time_start, time_end: shift.time_end, event_id: assignment.event_id, date: shift.date+days_offset).first_or_initialize
      new_shift.save
      unless Assignment.exists?(job_id: assignment.job_id, shift_id: new_shift.id, location_id: assignment.location_id)
        new_assignment = assignment.dup
        new_assignment.shift_id = new_shift.id
        new_assignment.save
        created = true
      end
      created
    end
  end

  def delete_assignment
    render_if_nonexistent(Assignment, params[:id], nil); return if performed?
    Assignment.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_tags
    event = Event.find(params[:event_id])
    if (event.closed? && current_user.staffer?) || event.cancelled?
      render json: {status: "error", message: "You can't edit Tags for a closed or cancelled Event"}
      return
    end

    if (new_record = params[:tags].delete("-1"))
      new_tag = Tag.new(name: new_record[:name], event_id: params[:event_id])
      new_tag.save
    end

    tags = Tag.find(params[:tags].keys)
    tags.each do |tag|
      attrs = params[:tags][tag.id.to_s]
      attrs.each { |k,v| attrs[k] = nil if v == "" }
      tag.update(tag_params(attrs))
      tag.save
    end

    render json: OfficeZoneSync.get_synced_response
  end


  def assignment_details
    # Just fetch the view.
  end
  #############################
  ##### Assignment Emails #####
  #############################

  def create_assignment_email_template
    aet = AssignmentEmailTemplate.new
    aet.event_id = params[:event_id]
    aet.name = params[:name]
    aet.save
    render json: OfficeZoneSync.get_synced_response
  end

  def duplicate_assignment_email_template
    new = AssignmentEmailTemplate.find(params[:id]).dup
    new.name = params[:name]
    new.save
    render json: OfficeZoneSync.get_synced_response({new_id: new.id})
  end

  def delete_assignment_email_template
    assignment_email_template = AssignmentEmailTemplate.find(params[:id])
    if assignment_email_template.name == 'Default'
      render json: {status: 'error', message: 'Cannot Delete Default Template'}
    else
      AssignmentEmailTemplate.find(params[:id]).destroy
      render json: OfficeZoneSync.get_synced_response
    end
  end

  def update_assignment_email_templates
    params[:templates].each do |template_id, values|
      template = AssignmentEmailTemplate.find(template_id)
      template.assign_attributes(assignment_email_template_params(values))
      template.save
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def fetch_assignment_email_preview
    gig = Gig.includes(assignments: [:shift, :job, :location]).find(params[:gig_id])
    tax_week = TaxWeek.find(params[:tax_week_id])
    template = AssignmentEmailTemplate.find(params[:template_id])
    @data = get_assignment_email_data_from_gig(gig, tax_week, template, params[:type])
    @preview = true
    render json: {
      subject: @data[:subject],
      missing: @data[:missing],
      body: render_to_string('staff_mailer/employee_assignment_details', layout: false)
    }
  end

  def send_assignment_emails
    gigs = Gig.includes(:event, prospect: [:account], assignments: [:shift, :job, :location]).find(OfficeZoneSync.reject_deleted(Gig, params[:gig_ids]))
    tax_week = TaxWeek.find(params[:tax_week_id])
    type = params[:type]
    template = AssignmentEmailTemplate.find(params[:template_id])

    gigs.each do |gig|
      data = get_assignment_email_data_from_gig(gig, tax_week, template, type)
      send_mail(StaffMailer.employee_assignment_details(gig.prospect, data))
      gig_tax_week = GigTaxWeek.where(gig_id: gig.id, tax_week_id: tax_week.id).first_or_create
      gig_tax_week.assignment_email_type = params[:type]
      gig_tax_week.assignment_email_template_id = params[:template_id]
      gig_tax_week.confirmed = true if params[:type] == 'Booked'
      gig_tax_week.save
    end

    if gigs.length > 0
      new = template.dup
      name = new.name.sub(/\s\(\w+:\sSent\s\d+\/\d+\/\d+ \d+:\d+:\d+\)$/,'')
      new.name = name + " (#{type}: Sent #{DateTime.now.strftime('%d/%m/%y %H:%M:%S')})"
      new.save
    end

    render json: OfficeZoneSync.get_synced_response({message: 'Sent!'})
  end

  def get_assignment_email_data_from_gig(gig, tax_week, template, type)
    data = {}
    data[:missing] = []
    prospect = gig.prospect

    data[:person] = prospect
    data[:name] = prospect.name

    event = gig.event
    shift_ids = Shift.where('event_id = ? AND ? <= date AND date <= ?', event.id, tax_week.date_start, tax_week.date_end).pluck(:id)
    this_weeks_assignment_ids = Assignment.where(shift_id: shift_ids).pluck(:id)

    event_name_location = "#{event.display_name}#{event.location ? " (#{event.location})" : ''}"

    data[:subject] =
        case type
        when 'Info'
          "Shift Info: #{event_name_location}"
        when 'Reserve'
          "Reserved Shifts for #{event_name_location}"
        when 'ShiftOffer'
          "Action Required - Shift Offer for #{event_name_location}"
        when 'CallToConfirm'
          "Call to confirm your shift at #{event_name_location}"
        when 'EmailToConfirm'
          "Email to confirm your shift at #{event_name_location}"
        when 'Booked'
          " #{event_name_location}"
        when 'BookedOffer'
          "Action Required - Shift Booking at #{event_name_location}"
        when 'Final'
          "Final Shift Details for #{event_name_location}"
        when 'Change'
          "URGENT: Shift Changes for #{event_name_location}"
        end

    data[:intro_statement] =
      case type
      when 'Info'
        "As requested, please find below your shift details for work at #{event_name_location}."
      when 'Reserve'
        "Below are your reserved shifts to work at #{event_name_location}. You will be prompted to confirm your attendance the week of this event to then receive the final contract information."
      when 'ShiftOffer'
        "To reserve the shifts below simply reply ‘YES’ and they are as good as yours. Thanks in advance for your continued commitment and we will be in touch soon with the next step in the process."
      when 'CallToConfirm'
        "Please call the Flair office to confirm you are attending the shifts below at #{event_name_location}."
      when 'EmailToConfirm'
        "To confirm your attendance at the reserved shifts below, simple reply ‘YES’, any alterations required just let us know."
      when 'Booked'
        "You are booked to work at #{event_name_location}. Final contract information will be sent a few days prior to your start date."
      when 'BookedOffer'
        "We have booked the shifts below for you. If you’re happy to accept, please indicate your commitment by replying ‘YES’ to this email."
      when 'Final'
        "Please review all your final contract information and we hope you have an enjoyable shift."
      when 'Change'
        "Please note that there have been changes to your assigned shifts for #{event_name_location}:"
      end

    if %w[CallToConfirm EmailToConfirm].include?(type)
      data[:intro_details] = []
      template.confirmation.present? ? data[:intro_details] << ['Confirming Times', Rinku.auto_link(template.confirmation)] : data[:missing] << 'Confirmation'
      data[:intro_details] << ['Numbers', '01612412441 / 07961988644'] if %w[CallToConfirm].include?(type)
    end

    data[:assignment_bullets] = []
    assignments = gig.assignments.select {|a| this_weeks_assignment_ids.include? a.id}.sort do |a,b|
      result = a.shift.date       <=> b.shift.date
      result = a.shift.time_start <=> b.shift.time_start if result == 0
      result = a.shift.time_end   <=> b.shift.time_end   if result == 0
      result = a.location.name    <=> b.location.name    if result == 0
      result = a.job.name         <=> b.job.name         if result == 0
      result
    end
    if assignments.length > 0 || gig.job_id
      if assignments.length > 0
        assignments.each do |a|
          data[:assignment_bullets] << "#{a.shift.date.strftime("%A #{a.shift.date.day.ordinalize} %b")} / #{a.shift.time_start.strftime('%l:%M%P')} - #{a.shift.time_end.strftime('%l:%M%P')} / #{a.job.pretty_name} @ #{a.location.name}"
        end
        jobs = Job.find(assignments.pluck(:job_id).uniq)
      elsif gig.job_id
        jobs = Job.find([gig.job_id])
      end
      if jobs.length > 0
        rate_strings = {}
        jobs.each do |job|
          if job.non_zero_rate? && prospect.include_in_brightpay?
            rate_string = "£#{sprintf('%.2f', job.rate_for_person(prospect, tax_week.date_end))}/hr (£#{sprintf('%.2f', job.base_pay_for_person(prospect, tax_week.date_end))} + £#{sprintf('%.2f', job.holiday_pay_for_person(prospect, tax_week.date_end))} Holiday Pay)"
            rate_strings[rate_string] ||= []
            rate_strings[rate_string] << job.pretty_name
          end
        end
        if rate_strings.keys.length > 1
          ##### If there's more than one rate, we'll put the job names on them
          new_rate_strings = {}
          rate_strings.each do |rate_string, job_names|
            if rate_strings.length > 1
              new_rate_strings[rate_string + ' for ' + job_names.join(' / ')] = []
            else
              new_rate_strings[rate_string] = []
            end
          end
          rate_strings = new_rate_strings
        end
        if rate_strings.keys.length > 0
          data[:assignment_bullets] << "Hourly rate #{rate_strings.keys.join('; ')} Paid #{date = tax_week.date_end.next_occurring(:friday); date.strftime("%A #{date.day.ordinalize} %b")}."
        end
      end
    end
    data[:assignment_bullets] << event.address
    if %w[Reserve ShiftOffer BookedOffer].include?(type)
      template.confirmation.present? ? data[:assignment_bullets] << "Confirm Your Shift: #{template.confirmation}" : data[:missing] << 'Confirmation'
    end

    if %w(Reserve ShiftOffer CallToConfirm EmailToConfirm Booked BookedOffer Final).include?(type)
      template.office_message.present? ? data[:office_message] = Rinku.auto_link(template.office_message) : data[:missing] << 'Message'
    end

    data[:details] = []
    if %w(Final).include?(type)
      template.on_site_contact.present?   ? data[:details] << ['On Site Contact',           Rinku.auto_link(template.on_site_contact)          ] : data[:missing] << 'On Site Contact'
      template.contact_number.present?    ? data[:details] << ['Contact Number',            Rinku.auto_link(template.contact_number)           ] : data[:missing] << 'Contact Number'
      data[:details] << :break if template.on_site_contact.present? || template.contact_number.present?
      template.arrival_time.present?      ? data[:details] << ['Arrival Time',              Rinku.auto_link(template.arrival_time)              ] : data[:missing] << 'Arrival Time'
      template.meeting_location.present?  ? data[:details] << ['Meeting Location',          Rinku.auto_link(template.meeting_location)         ] : data[:missing] << 'Meeting Location'
      template.meeting_location_map_link  ? data[:details] << ['Map Link',                  Rinku.auto_link(template.meeting_location_map_link)] : data[:missing] << 'Meeting Location Coordinates'
      data[:details] << :break if template.arrival_time.present? || template.meeting_location.present? || template.meeting_location_map_link
    end

    if %w(Booked BookedOffer Final).include?(type)
      if jobs && jobs.length > 0
        job_descriptions = []
        jobs.each do |job|
          if job.description.blank?
            data[:missing] << "#{job.name} Job Description"
          else
            if jobs.length == 1
              job_descriptions << job.description
            else
              job_descriptions << "#{job.name}: #{job.description}"
            end
          end
        end
        data[:details] << ['Job Role Details', Rinku.auto_link(job_descriptions.join(', '))] if job_descriptions.length > 0
      end
    end
    if %w(Reserve ShiftOffer BookedOffer Final).include?(type)
      template.uniform.present?         ? data[:details] << ['Uniform',         Rinku.auto_link(template.uniform)         ] : data[:missing] << 'Uniform'
    end
    if %w(Final).include?(type)
      template.welfare.present?         ? data[:details] << ['Welfare',         Rinku.auto_link(template.welfare)         ] : data[:missing] << 'Welfare'
    end
    if %w(Reserve ShiftOffer Booked BookedOffer Final).include?(type)
      template.transport.present?       ? data[:details] << ['Transport',       Rinku.auto_link(template.transport)       ] : data[:missing] << 'Transport'
    end
    if %w(Reserve ShiftOffer CallToConfirm EmailToConfirm Booked BookedOffer Final Change).include?(type)
      template.details.present?         ? data[:details] << ['Event Details',   Rinku.auto_link(template.details)         ] : data[:missing] << 'Details'
      template.additional_info.present? ? data[:details] << ['Additional Info', Rinku.auto_link(template.additional_info) ] : data[:missing] << 'Additional Info'
    end

    if %w(Final).include?(type)
      data[:details] << ['Employee Admin', 'Timesheets are everything; please confirm your attendance and all hours worked upon shift competition. Breaks are a legal and ethical requirement and unpaid unless indicated. Finish times are subject to change within reason. Make sure Flair has your correct bank details and that your tax starter declaration form, on your staff profile, is always up-to-date.']
    end

    data[:concluding_statement]= Rinku.auto_link(
      case type
      when 'Info'
        'If you have any question or concerns relating to your above shifts don’t hesitate to contact the office team, we are here to work for you.'
      when 'Reserve'
        'Your continued interest is appreciated and assists with our pre-event organisation. If at any point you can no longer commit, or wish to change shifts, please contact our office team. If a shift change occurs you will be notified straight away.  Final details are always sent after shifts are booked and confirmed.'
      when 'ShiftOffer'
        "We will continue with our pre-event organisation, if at any point you can no longer commit or wish to change shifts please contact our office team. If any shift changes occur you will be notified straight away. Final details are always sent once your shifts are booked and confirmed."
      when 'CallToConfirm', 'EmailToConfirm'
        'Once you have confirmed your shifts we will send out your final contract details. If at any point you can no longer commit or have questions contact our office team, we are here working for you.'
      when 'Booked'
        'Remember at any point if you have any question or need to alter your shifts, simply contact the office team, as we are here to help.'
      when 'BookedOffer'
        "Final contract details will follow shortly. Remember at any point if you have any question or need to alter your shifts, simply contact the office team as we are here to help."
      when 'Final'
        "If you can no longer work, need to change shifts or have any questions, don't hesitate to contact our office team.  Flair operates a system that rate performance and monitors commitment levels. Failure to attend or cancelling without sufficient notice could mean your removal from future contracts. Let\’s keep in communication."
      when 'Change'
        'If you are unable to work due to these changes please contact the office team to discuss as soon as possible, otherwise we will see you there.'
      end)

    if %w(Reserve Booked Final).include?(type)
      data[:postscript] = ''
      EventClient.where(event_id: event.id).each do |event_client|
        client = event_client.client
        booking = event_client.booking
        data[:postscript] += '\n' unless data[:postscript] == ''
        data[:postscript] += "Flair Events has engaged you to work for #{client.name}"
        if client.company_type.present?
          data[:postscript] += " and they are the #{client.company_type} for this event."
        else
          data[:postscript] += '.'
          data[:missing] << 'Company Type (Client)'
        end
        if booking.health_safety.present?
          data[:postscript] += " This Company has highlighted the following Health & Safety considerations when you undertake this work; they will have addressed and made steps to minimise these as part of their Risk Assessment procedures. However, you also have a personal responsibility to minimise the impact of these factors: "
          data[:postscript] += booking.health_safety
        else
          data[:missing] << 'Health & Safety (Booking)'
        end
      end
    end

    if assignments.any?
      ical = Icalendar::Calendar.new
      assignments.each do |a|
        ical.event do |e|
          e.dtstart     = a.shift.datetime_start
          e.dtend       = a.shift.datetime_end
          e.summary     = "(Summary)"
          e.description = "(Description)"
        end
      end
      data[:icalendar] = ical
    end

    data
  end

# NAME:        delete_tag
# DESCRIPTION:
  def delete_tag
    render_if_nonexistent(Tag, params[:id], nil); return if performed?
    Tag.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def fetch_profile
    @prospect = Prospect.find(params[:id])
    @preferred_contact_time = []
    @preferred_contact_time << 'Morning' if @prospect.prefers_morning
    @preferred_contact_time << 'Afternoon' if @prospect.prefers_afternoon
    @preferred_contact_time << 'Early Evening' if @prospect.prefers_early_evening
    @preferred_contact_time << 'Midweek' if @prospect.prefers_midweek
    @preferred_contact_time << 'Weekend' if @prospect.prefers_weekend
    render layout: false
  end

  def fetch_timesheet_notes
    @prospect = Prospect.find(params[:id])
    @profile_timesheet_notes = []
    Gig.where(prospect_id: @prospect.id).includes(:event, timesheet_entries: [:tax_week]).each do |gig|
      gig.timesheet_entries.each do |tse|
        @profile_timesheet_notes << { date: tse.tax_week.date_end, event: gig.event.name, rating: tse.rating, notes: tse.notes} if (tse.notes.present? || tse.rating)
      end
    end
    @profile_timesheet_notes = @profile_timesheet_notes.sort_by {|note| note[:date]}.reverse
    @profile_timesheet_notes = @profile_timesheet_notes.uniq
    render layout: false
  end

  def fetch_change_request_log
    @history = DetailsHistory.where(prospect_id: params[:id].to_i).order(:created_at).reverse
    render layout: false
  end

  def accept_change_request
    if ChangeRequest.exists? params[:id]
      cr = ChangeRequest.find(params[:id])
      cr_id = todo_id_for_cr(cr) # see comment in #get_todos

      ChangeRequest.fields.each do |k|
        cr.prospect[k] = cr[k] if cr[k].present?
      end

      if cr.prospect.save
        cr.destroy
        Deletion.create!(table: 'todos', record_id: cr_id)
        render json: {status: 'ok', tables: {prospects: [export_prospect_object(cr.prospect)]}, deleted: {todos: [cr_id]}}
      else
        render json: {status: 'error', message: cr.prospect.errors.full_messages.to_sentence}
      end
    else
      render json: {status: 'ok', deleted: {todos: [todo_id_for_cr({id: params[:id]})]}, message: "This change request had already been processed"}
    end
  end

  def reject_change_request
    if ChangeRequest.exists? params[:id]
      cr = ChangeRequest.find(params[:id])
      cr_id = todo_id_for_cr(cr) # see comment in #get_todos
      cr.destroy
      Deletion.create!(table: 'todos', record_id: cr_id)
      render json: {status: 'ok', deleted: {todos: [cr_id]}}
    else
      render json: {status: 'ok', deleted: {todos: [todo_id_for_cr({id: params[:id]})]}, message: "This change request had already been processed"}
    end
  end

  #############################
  ##### Team Leader Roles #####
  #############################

  def update_team_leader_roles
    params[:team_leader_roles].each do |id, p|
      team_leader_role = ((id == "-1") ? TeamLeaderRole.new : TeamLeaderRole.find(id))
      p[:enabled] ||= false #checkboxes only send a value if true
      team_leader_role.assign_attributes(team_leader_role_params(p))
      team_leader_role.event_id = params[:event_id]
      team_leader_role.enabled = p[:enabled] || false # Checkboxes only send a value if true
      team_leader_role.save
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_team_leader_role
    render_if_nonexistent(TeamLeaderRole, params[:id], nil); return if performed?
    TeamLeaderRole.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  ###################
  ##### Clients #####
  ###################

  def create_client
    client = Client.new
    client.assign_attributes(client_params(params[:client]).reject { |k,v| v.blank? })
    client.save
    render json: OfficeZoneSync.get_synced_response
  end

  def update_client
    if (client = Client.find_by_id(params[:id]))
      client.assign_attributes(client_params(params[:client]).reject { |k,v| v.blank? && client[k].blank? })
      client.save
      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: 'error', message: 'Could Not Find Specified Client'}
    end
  end

  def delete_client
    render_if_nonexistent(Client, params[:id], nil); return if performed?
    Client.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_client_contacts
    if (new_record = params[:client_contacts].delete("-1"))
      new_client_contact = ClientContact.new
      new_client_contact.assign_attributes(client_contact_params(new_record).reject { |k,v| v.blank? })
      new_client_contact.client_id = params[:client_id]
      if new_client_contact.save
        account = Account.new(user_id: new_client_contact.id, user_type: 'ClientContact')
        account.save
      end
    end

    client_contacts = ClientContact.find(params[:client_contacts].keys)
    client_contacts.each do |client_contact|
      client_contact.assign_attributes(client_contact_params(params[:client_contacts][client_contact.id.to_s]).reject { |k,v| v.blank? && client_contact[k].blank? })
      client_contact.save
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_client_contact
    render_if_nonexistent(ClientContact, params[:id], nil); return if performed?
    ClientContact.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def invite_client_contact
    render_if_nonexistent(ClientContact, params[:id], nil); return if performed?
    client_contact = ClientContact.find(params[:id])

    if client_contact.account_activated?
      message = "#{client_contact.first_name} #{client_contact.last_name}'s Account has already been activated'"
    else
      account = client_contact.account
      account.generate_one_time_token!
      account.save
      send_mail(ClientMailer.activate_account(client_contact, account))
      client_contact.account_status = 'INVITED'
      client_contact.save
      message = "Invitation Sent!"
    end
    render json: OfficeZoneSync.get_synced_response(message: message)
  end

  ######################
  ##### Interviews #####
  ######################

  # NAME:        create_bulk_interview
  # DESCRIPTION: Creates a bulk interview.
  def create_bulk_interview
    [:date_start, :date_end].each { |k| params[:bulk_interview][k] = params[:bulk_interview][k].to_date if params[:bulk_interview][k].present? }
    params[:bulk_interview][:post_code].strip! if params[:bulk_interview][:post_code]

    bulk_interview = BulkInterview.new
    bulk_interview.assign_attributes(bulk_interview_params(params[:bulk_interview].except(:id)).reject { |k,v| v.blank? })
    if bulk_interview.save
      associate_events_with_bulk_interview(bulk_interview.id, params[:bulk_interview_events])
    end
    render json: OfficeZoneSync.get_synced_response
  end

  # NAME:        update_bulk_interview
  # DESCRIPTION: More of the same
  def update_bulk_interview
    [:date_start, :date_end].each { |k| params[:bulk_interview][k] = params[:bulk_interview][k].to_date if params[:bulk_interview][k].present? }
    params[:bulk_interview_events] ||= []
    params[:bulk_interview].each { |k,v| params[:bulk_interview][k] = nil if v == "" }
    params[:bulk_interview][:post_code].strip! if params[:bulk_interview][:post_code]

    bulk_interview = BulkInterview.find(params[:bulk_interview][:id])
    bulk_interview.assign_attributes(bulk_interview_params(params[:bulk_interview].except(:id)))

    if bulk_interview.save && params[:bulk_interview_events]
      associate_events_with_bulk_interview(bulk_interview.id, params[:bulk_interview_events])
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def delete_bulk_interview
    render_if_nonexistent(BulkInterview, params[:id], nil); return if performed?
    BulkInterview.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  def update_interview_blocks
    updated_ibs = []

    #New Interview Block
    if (new_attrs = params[:interviewBlocks].delete("-1"))
      new_ib = InterviewBlock.new
      new_attrs.each { |k,v| new_attrs[k] = nil if v == "" }
      new_attrs[:date] = get_ib_date(new_attrs[:date])
      new_attrs[:bulk_interview_id] = params[:bulk_interview_id]
      new_attrs[:time_start] = "10:00"
      new_attrs[:time_end] = "13:00"
      new_attrs[:number_of_applicants_per_slot] = 1
      new_attrs[:slot_mins] = 30

      if new_attrs[:is_morning] == nil
        new_attrs[:is_morning] = false
        new_attrs[:morning_applicants] = 0
      end
      if new_attrs[:is_afternoon] == nil
        new_attrs[:is_afternoon] = false
        new_attrs[:afternoon_applicants] = 0
      end
      if new_attrs[:is_evening] == nil
        new_attrs[:is_evening] = false
        new_attrs[:evening_applicants] = 0
      end

      new_attrs[:morning_applicants] = new_attrs[:morning_applicants] == nil ? 0 : new_attrs[:morning_applicants]
      new_attrs[:afternoon_applicants] = new_attrs[:afternoon_applicants] == nil ? 0 : new_attrs[:afternoon_applicants]
      new_attrs[:evening_applicants] = new_attrs[:evening_applicants] == nil ? 0 : new_attrs[:evening_applicants]

      new_ib.update(interview_block_params(new_attrs))
      updated_ibs << new_ib if new_ib.save
    end

    #Existing Interview Blocks
    ibs = InterviewBlock.find(params[:interviewBlocks].keys)
    ibs.each do |ib|
      attrs = params[:interviewBlocks][ib.id.to_s]
      attrs[:date] = get_ib_date(attrs[:date])
      attrs[:time_start] = "10:00"
      attrs[:time_end] = "13:00"
      attrs[:number_of_applicants_per_slot] = 1
      attrs[:slot_mins] = 30

      if attrs[:is_morning] == nil
        attrs[:is_morning] = false
        attrs[:morning_applicants] = 0
      end
      if attrs[:is_afternoon] == nil
        attrs[:is_afternoon] = false
        attrs[:afternoon_applicants] = 0
      end
      if attrs[:is_evening] == nil
        attrs[:is_evening] = false
        attrs[:evening_applicants] = 0
      end

      attrs[:morning_applicants] = attrs[:morning_applicants] == nil ? 0 : attrs[:morning_applicants]
      attrs[:afternoon_applicants] = attrs[:afternoon_applicants] == nil ? 0 : attrs[:afternoon_applicants]
      attrs[:evening_applicants] = attrs[:evening_applicants] == nil ? 0 : attrs[:evening_applicants]

      attrs.each { |k,v| attrs[k] = nil if v == "" }
      ib.update(interview_block_params(attrs))
      updated_ibs << ib if ib.save
    end

    #Generate Interview slots from blocks
    updated_interview_slots = []
    updated_ibs.each do |ib|
      (ib.time_start..ib.time_end).time_step(ib.slot_mins.minutes) do |time_start|
        if time_start < ib.time_end
          is = InterviewSlot.where(interview_block_id: ib.id, time_start: time_start).first_or_initialize
          is.interview_block_id = ib.id
          is.time_start = time_start
          is.time_end = time_start+ib.slot_mins.minutes
          is.save
          updated_interview_slots << is
        end
      end
      #Delete any interview slots that are no longer valid
      # InterviewSlot.where(interview_block_id: ib.id).where.not(id: updated_interview_slots).destroy_all
    end
    render json: OfficeZoneSync.get_synced_response
  end

  # NAME:        delete_interview_block
  # DESCRIPTION: Remove a Job (if it does not have any scheduled interviews yet
  def delete_interview_block
    render_if_nonexistent(InterviewBlock, params[:id], nil); return if performed?
    InterviewBlock.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  private

  def get_ib_date(date)
    date && date != '' ? Date.strptime(date, /\D\d\d\z/ =~ date ? '%d/%m/%y' : '%d/%m/%Y' ) : ''
  end

  def associate_events_with_bulk_interview(bulk_interview_id, event_ids)
    event_ids ||= []
    event_ids = event_ids.reject {|c| c.blank?}
    event_ids = event_ids.map {|i| i.to_i}
    BulkInterviewEvent.where(bulk_interview_id: bulk_interview_id).each do |bie|
      if event_ids.include? bie.event_id
        #Remove event_ids that are no longer there, don't bother changing ones that already exist
        event_ids.delete(bie.event_id)
      else
        #Remove event_ids that have been removed
        bie.destroy
      end
    end
    event_ids.each do |event_id|
      #Add new events
      bie = BulkInterviewEvent.new
      bie.assign_attributes({bulk_interview_id: bulk_interview_id, event_id: event_id})
      bie.save
    end
  end

####################
##### Invoices #####
####################

public

  def create_invoice
    invoice = Invoice.new
    if params[:client_id] && params[:event_id]
      event_client = EventClient.where(client_id: params[:client_id], event_id: params[:event_id]).first
      invoice.event_client_id = event_client.id if event_client
    end
    invoice.assign_attributes(invoice_params(params[:invoice]).reject { |k,v| v.blank? })
    invoice.save
    render json: OfficeZoneSync.get_synced_response
  end

  def update_invoice
    params[:invoices] = {}
    params[:invoices][params[:id]] = params[:invoice]
    if Invoice.exists? params[:id]
      update_invoices
    else
      render json: {status: "ok", message: "Invoice was previously deleted.", deleted: {invoices: params[:id]}}
    end
  end

  def update_invoices
    if params[:invoices]
      invoice_ids = params[:invoices].keys
      invoice_ids.each do |invoice_id|
        if (invoice = Invoice.find_by(id: invoice_id))
          if params[:client_id] && params[:event_id]
            event_client = EventClient.where(client_id: params[:client_id], event_id: params[:event_id]).first
            invoice.event_client_id = event_client.id if event_client
          end
          attrs = params[:invoices][invoice.id.to_s]
          invoice.assign_attributes(invoice_params(attrs.except(:booking_invoicing_notes)).reject { |k,v| v.blank? && invoice[k].blank? })
          if invoice.save
            booking = Booking.where(event_client_id: invoice.event_client_id).first
            unless booking
              booking = Booking.new
              booking.event_client_id = invoice.event_client_id
            end
            booking.invoicing = attrs[:booking_invoicing_notes]
            booking.save
          end
        end
      end
    end

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_invoice
    render_if_nonexistent(Invoice, params[:id], nil); return if performed?
    Invoice.find(params[:id]).destroy
    render json: OfficeZoneSync.get_synced_response
  end

  #############################
  ##### Timesheet Entries #####
  #############################

  def create_timesheet_entries_for_event
    tax_week = TaxWeek.find(params[:tax_week_id])
    if previous_payroll_processed?(tax_week)
      event = Event.find(params[:event_id])

      if params[:prospect_ids]
        # Create pay_weeks only for selected prospects
        gigs = Gig.includes(gig_assignments: [:timesheet_entry, assignment: [:shift]]).where(event_id: event.id, prospect_id: params[:prospect_ids], status: 'Active')
      else
        # Create pay_weeks for all employees in event
        gigs = Gig.includes(gig_assignments: [:timesheet_entry, assignment: [:shift]]).where(event_id: event.id, status: 'Active')
      end

      gigs.each do |gig|
        gig.gig_assignments.select {|gig_assignment| tax_week.date_start <= gig_assignment.shift.date && gig_assignment.shift.date <= tax_week.date_end }.each do |gig_assignment|
          unless gig_assignment.timesheet_entry
            timesheet_entry = TimesheetEntry.new(gig_assignment_id: gig_assignment.id, tax_week_id: tax_week.id, status: params[:status], time_start: gig_assignment.shift.time_start)
            timesheet_entry.save
          end
        end
      end

      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: 'error', message: "You must submit last week's payroll before processing this week's"}
    end
  end

  def update_timesheet_entries
    messages = []
    params[:data].each do |id,params|
      if (timesheet_entry = TimesheetEntry.find(id))
        params.each { |param, val| val = param = nil if val == ''}
        old_rating = timesheet_entry.rating
        pay_week_updated_at = timesheet_entry.pay_week.updated_at
        timesheet_entry.update(timesheet_params(params))
        timesheet_entry.save
      else
        messages << "Could not find Timesheet Entry (id: #{id})"
      end
    end

    render json: OfficeZoneSync.get_synced_response({message: messages.to_sentence})
  end

  def delete_timesheet_entries
    messages = []
    params[:ids].each do |id|
      if (timesheet_entry = TimesheetEntry.find_by_id(id))
        ##### We want to keep the timesheets and gig_assignments in sync, so we will delete any associated
        ##### gig_assignment when deleting a timesheet_entry
        gig_assignment = GigAssignment.includes(:timesheet_entry).find(timesheet_entry.gig_assignment_id)
        gig_assignment.timesheet_entry.destroy if gig_assignment.timesheet_entry.status != 'SUBMITTED'
        gig_assignment.reload # Reload so that the timesheet entry deletion is seen
        gig_assignment.destroy #This will automatically destroy the associated timesheets
      end
    end
    render json: OfficeZoneSync.get_synced_response
  end

  def get_scanned_timesheet_name(event, tax_week)
    "#{tax_week.tax_year.date_start.year}-#{tax_week.tax_year.date_end.year}_#{tax_week.week}_#{event.id}"
  end

  def upload_scanned_timesheets
    name = get_scanned_timesheet_name(Event.find(params[:event_id]), TaxWeek.find(params[:tax_week_id]))
    errors = []
    files = []
    n=0
    while (file = params["scan#{n}".to_sym]) do
      files << file
      n = n+1
    end

    puts("files: #{files.inspect}")

    if request.post?
    #   if uploaded = params[:scan]
    #     directory = File.join(Flair::Application.config.shared_dir, 'scanned_timesheets')
    #     result    = handle_general_upload(uploaded, directory, name)
    #     case result
    #       when :ok
    #         true
    #       when :thumbnail_failed
    #         errors << "A server error occurred while processing #{uploaded.original_filename}. The file may be corrupted. If this happens every time you try to upload this file, please contact Flair for help."
    #       when :not_enough_space
    #         errors << "Sorry, there is not enough free space on the server's hard drive to store your photo."
    #       when :too_large
    #         errors << "Photo files cannot be larger than 20 megabytes. Please upload a different photo file."
    #       when :unknown_image_type
    #         errors <<  "Photo files must be .jpg, .jpeg, .gif, or .png files. Please upload a different photo file."
    #       when :blank
    #         errors <<  "Please use the upload button to choose a picture before submitting"
    #       else
    #         errors << "Error for photo: #{result}"
    #     end
    #   end

      if errors.empty?
        render json: {status: "ok", message: "Sorry, Scans Uploading Not Implemented"}
      else
        render json: {status: "error", message: errors.to_sentence}
      end
    end
  end

####################
##### Pay Week #####
####################

  # receives an event ID in params[:id]
  # creates pay week records for all the employees with gigs in that event,
  #   but does NOT create duplicates of pay week records which already exist
  def create_pay_weeks_for_event
    tax_week = TaxWeek.find(params[:tax_week_id])
    if previous_payroll_processed?(tax_week)
      event_id = params[:id]
      if params[:prospect_ids]
        # Create pay_weeks only for selected prospects
        gigs = Gig.where(event_id: event_id, prospect_id: params[:prospect_ids], status: 'Active')
      else
        # Create pay_weeks for all employees in event
        gigs = Gig.where(event_id: event_id, status: 'Active')
      end

      gigs.each do |gig|
        ##### If there are gig_assignments, use those. Otherwise just create with blank Job
        job_ids = gig.gig_assignments.map { |gig_assignment| gig_assignment.assignment.job_id}.uniq
        job_ids = [nil] if job_ids.empty?

        job_ids.each do |job_id|
          if job = Job.find_by_id(job_id)
            rate = job.rate_for_person(gig.prospect, tax_week.date_end)
          else
            rate = nil
          end
          pay_week = PayWeek.new
          pay_week.tax_week_id = tax_week.id
          pay_week.prospect_id = gig.prospect_id
          pay_week.event_id    = gig.event_id
          pay_week.job_id      = job_id
          pay_week.rate        = rate
          pay_week.status      = params[:status] || "NEW"
          pay_week.type        = 'MANUAL'

          pay_week.save
        end
      end

      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: 'error', message: "You must submit last week's payroll before processing this week's"}
    end
  end

  def create_pay_weeks_from_pay_weeks
    messages = []
    params[:ids].each do |id|
      if (pay_week_orig = PayWeek.find(id))
        pay_week = PayWeek.new
        [:tax_week_id, :prospect_id, :event_id, :status].each {|key| pay_week[key] = pay_week_orig[key]}
        pay_week.rate = 0
        pay_week.type = 'MANUAL'
        pay_week.save
      end
    end
    render json: OfficeZoneSync.get_synced_response
  end

  ##### receives a Hash of { id => { pay week fields }} in params[:pay-weeks]
  # Test URL: http://0.0.0.0:3000/office/update_pay_weeks?pay_weeks[1][prospect_id]=10&pay_weeks[2][monday]=7
  def update_pay_weeks # one or many
    messages = []
    events_to_invoice = {}

    params[:data].each do |id,pw_params|
      if (pay_week = PayWeek.includes(:tax_week).find(id))
        if params['autocalc']
          #Sometimes the user deletes a cell instead of entering zero. If so, set it to zero.
          #Put this first because following steps may rely on hours being set properly
          %w(monday tuesday wednesday thursday friday saturday sunday).each { |day| pw_params[day] = 0 if pw_params[day] == '' }
          if pw_params[:job_name] == ''
            pw_params[:job_id] = nil
            pw_params.delete(:job_name)
          end
        end

        unless pw_params.key?(:job_id)
          if (job = Job.where(event_id: pay_week.event_id, name: pw_params.delete(:job_name)).first)
            pw_params[:job_id] = job.id
            pw_params[:rate]   = job.rate_for_person(pay_week.prospect, pay_week.tax_week.date_end)
          else
            pw_params[:job_id] = pay_week.job_id
          end
        end

        pay_week.assign_attributes(pay_week_params(pw_params))
        events_to_invoice[pay_week.event] = pay_week.tax_week if pay_week.status_changed?(to: 'PENDING') && pay_week.event
        pay_week.save
        if pay_week.status == 'SUBMITTED' && (event = pay_week.event)
          if event.status == 'FINISHED' && event.date_end <= pay_week.tax_week.date_end
            event.status = 'CLOSED'
            event.save
          end
        end
      else
        raise "Invalid tax week ID passed"
      end
    end

    events_to_invoice.each { |event, tax_week| event.invoice_if_needed(tax_week) }

    render json: OfficeZoneSync.get_synced_response
  end

  def delete_pay_weeks
    PayWeek.where(id: params[:ids]).destroy_all
    render json: OfficeZoneSync.get_synced_response
  end

  def add_remove_pay_weeks
    tax_week = TaxWeek.find(params[:tax_week_id])
    if previous_payroll_processed?(tax_week)
      if params[:prospects_add]
        params[:prospects_add].each do |prospect_id|
          prospect = Prospect.find(prospect_id)
          pay_week = PayWeek.new(prospect_id: prospect_id, tax_week_id: params[:tax_week_id])
          pay_week.status = params[:status]
          pay_week.type = 'MANUAL'
          pay_week.event_id = params[:event_id] if Event.find_by_id(params[:event_id])
          if (gig = Gig.includes(:job).where(prospect_id: prospect_id, event_id: params[:event_id]).first)
            if gig.job
              pay_week.job_id = gig.job.id
              pay_week.rate = gig.job.rate_for_person(prospect, tax_week.date_end)
            end
          end
          pay_week.save
        end
      end

      if params[:prospects_remove]
        pw_params = {prospect_id: params[:prospects_remove], tax_week_id: params[:tax_week_id]}
        pw_params[:event_id] = params[:event_id] if !params[:event_id].empty?
        PayWeek.where(pw_params).destroy_all
      end
      render json: OfficeZoneSync.get_synced_response
    else
      render json: {status: 'error', message: "You must submit last week's payroll before processing this week's"}
    end
  end

  # receives tax week and year
  # sends .zip file as reply
  # Test URL: http://0.0.0.0:3000/office/export_pay_week?tax_year=2014&tax_week=49
  def export_pay_week
    pay_weeks = PayWeek.includes(:job, tax_week: [:tax_year], prospect: [:nationality], event: [:event_category]).where(status: params[:status], tax_week_id: params[:tax_week_id])

    unless pay_weeks.empty?
      tax_week = pay_weeks.first.tax_week

      #If anyone has not entered their tax code, set it for them
      pay_weeks.each do |pay_week|
        unless pay_week.prospect.tax_choice
          pay_week.prospect.tax_choice = 'C'
          pay_week.prospect.save!
        end
      end
      update_payroll_activity_and_history(pay_weeks) if latest_tax_week_for_payroll?(tax_week)
      pay_weeks_to_brightpay(pay_weeks)
    else
      render json: { status: 'error', message: "No Payroll Entries for this tax week" }
    end
  end

  def check_if_pay_weeks_okay_to_export
    tax_week = TaxWeek.find(params[:tax_week_id])
    error_message = nil
    case params[:status]
      when 'NEW'
        error_message = "You can't export pay_weeks in a 'new' state"
      when 'PENDING'
        pay_weeks = PayWeek.where(status: 'NEW', tax_week_id: tax_week.id)
        unless pay_weeks.empty?
          error_message = "You still have pay_week entries in 'NEW' state. Please move them to PENDING or delete them"
        end
      when 'SUBMITTED'
        pay_weeks = PayWeek.where(status: ['NEW', 'PENDING'], tax_week_id: tax_week.id)
        unless pay_weeks.empty?
          error_message = "You still have pay_week entries in 'NEW' and/or 'PENDING' state. Please move them to SUBMITTED"
        end
      else
        error_message = "Invalid status #{params[:status]}"
    end

    if error_message
      render json: { status: 'error', message: error_message }
    else
      render json: { status: 'ok' }
    end
  end

  def payroll_detail_changes
    tax_week = TaxWeek.find(params[:tax_week_id])
    pay_weeks = PayWeek.where(status: ['PENDING', 'SUBMITTED'], tax_week_id: tax_week.id)
    update_payroll_activity_and_history(pay_weeks) if latest_tax_week_for_payroll?(tax_week)
    @tax_week_description = "(#{tax_week.tax_year.date_start.year}-#{tax_week.tax_year.date_end.year}) #{tax_week.week}: #{tax_week.date_start} - #{tax_week.date_end}"

    @leavers = []
    PayrollActivity.includes(:prospect).where(tax_week_id: tax_week.id, action: 'REMOVED').each do |payroll_activity|
      @leavers << {name: payroll_activity.prospect.name, id: payroll_activity.prospect.id}
    end
    @leavers = @leavers.sort_by { |p| p[:name]}

    @returners = []
    tax_week_ids = this_years_tax_week_ids_up_to(tax_week)
    PayrollActivity.includes(:prospect).where(tax_week_id: tax_week.id, action: 'ADDED').each do |payroll_activity|
      if PayrollActivity.where(tax_week_id: tax_week_ids, prospect_id: payroll_activity.prospect_id, action: 'REMOVED').exists?
        @returners << {name: payroll_activity.prospect.name, id: payroll_activity.prospect.id}
      end
    end
    @returners = @returners.sort_by { |p| p[:name]}

    @changes = pay_week_details_changes(tax_week.id)
    puts @changes
    puts tax_week.id
    puts "==========================================================="
  end

  def this_years_tax_week_ids_up_to(tax_week)
    TaxWeek.where("tax_year_id = ? AND date_start <= ?", tax_week.tax_year_id, tax_week.date_start).pluck(:id)
  end

  def latest_tax_week_for_payroll?(tax_week)
    next_tax_week = TaxWeek.where(date_start: tax_week.date_start+1.week).first
    PayWeek.where(tax_week_id: next_tax_week.id).none?
  end

  def previous_payroll_processed?(tax_week)
    last_tax_week = TaxWeek.where(date_start: tax_week.date_start-1.week).first
    PayWeek.where(tax_week_id: last_tax_week.id, status: ['NEW', 'PENDING']).none?
  end

  def update_payroll_activity_and_history(pay_weeks)
    raise "All Pay Weeks must be in the same Tax Week" if pay_weeks.pluck(:tax_week_id).uniq.length > 1
    tax_week = pay_weeks.first.tax_week
    this_years_tax_week_ids_up_to_tax_week = this_years_tax_week_ids_up_to(tax_week)
    this_weeks_prospect_ids = pay_weeks.pluck(:prospect_id).uniq

    ####################
    ##### CLEAN_UP #####
    ####################
    ##### It's possible that a person got flagged for removal this week, but later got added to payroll.
    ##### - Remove the REMOVED PayrollActivity
    PayrollActivity.where(prospect_id: this_weeks_prospect_ids, action: 'REMOVED', tax_week_id: tax_week.id).destroy_all

    ##### It's possible that a person was flagged for addition, but is no longer part of payroll.
    ##### - Remove this week's ADDED PayrollActivity
    ##### - Remove this week's PayWeek Details History
    PayrollActivity.where(tax_week_id: tax_week.id, action: 'ADDED').where.not(prospect_id: this_weeks_prospect_ids).destroy_all
    PayWeekDetailsHistory.where(tax_week_id: tax_week.id).where.not(prospect_id: this_weeks_prospect_ids).destroy_all

    this_weeks_prospect_ids.each do |prospect_id|
      ##### Indicate that user has been added IF they:
      #####   Don't have a previous PayrollActivity
      #####   OR Their previous PayrollActivity was 'remove'

      payroll_activity_actions = PayrollActivity.joins(:tax_week).where(tax_week_id: this_years_tax_week_ids_up_to_tax_week, prospect_id: prospect_id).order('tax_weeks.date_start asc').pluck(:action)

      if payroll_activity_actions.length == 0 || payroll_activity_actions.last == 'REMOVED'
        payroll_activity = PayrollActivity.where(prospect_id: prospect_id, tax_week: tax_week).first_or_create
        payroll_activity.action = 'ADDED'
        payroll_activity.save!
      end
    end

    ##### Create a snapshot of attributes used for this person for their pay.
    ##### Unlike PayrollActivity, which can be safely recreated, PayWeekDetailsHistory is ONLY valid the week it's created
    ##### because it grabs the current values for the prospect. We don't want to overwrite old ones ever.
    if latest_tax_week_for_payroll?(tax_week)
      this_weeks_prospect_ids.each do |prospect_id|
        pwdh = PayWeekDetailsHistory.includes(:prospect).where(prospect_id: prospect_id, tax_week_id: tax_week.id).first_or_create
        pwdh.copy_from_prospect(pwdh.prospect)
        pwdh.save!
      end
    end
    ##### We detect any users that should be removed based on the following criteria:
    ##### - Last Payroll Activity was 'ADDED'
    ##### - Was not paid in the last two tax weeks (which, by definition, includes this week's)
    ##### - Is not working an event that starts in the next 4 tax weeks
    recently_paid_prospect_ids = PayWeek.joins(:tax_week).where("date_end > ?", (tax_week.date_start - 2.weeks)).pluck(:prospect_id)
    PayrollActivity.includes(:prospect).joins(:tax_week).where(tax_week_id: this_years_tax_week_ids_up_to_tax_week).order('tax_weeks.date_start asc').group_by(&:prospect).each do |prospect, payroll_activities|
      if (payroll_activities.last.action == 'ADDED' &&
          !recently_paid_prospect_ids.include?(prospect.id) &&
          prospect.gigs.joins(:event).where("events.date_end > ? AND events.date_start <= ?", tax_week.date_end, (tax_week.date_end + 4.weeks)).none?)
        payroll_activity = PayrollActivity.where(prospect: prospect, tax_week: tax_week).first_or_create
        payroll_activity.action = 'REMOVED'
        payroll_activity.save!
      end
    end
  end

  def pay_week_details_changes(tax_week_id)
    changes = {}
    tax_week = TaxWeek.find(tax_week_id)

    prospect_ids = (PayWeekDetailsHistory.where(tax_week_id: tax_week.id)).map { |pwdh| pwdh.prospect_id }

    prospect_ids.sort_by! { |p_id| Prospect.find(p_id).name }.each do |p_id|
      #Only consider details history from the tax week were the user was last added.
      start_tax_week = TaxWeek.find(PayrollActivity.joins(:tax_week).where(prospect_id: p_id, action: 'ADDED').order('tax_weeks.date_start asc').last.tax_week_id)

      tax_week_ids = TaxWeek.where('date_start >= ? AND date_start <= ?', start_tax_week.date_start, tax_week.date_start).pluck(:id)

      pwdhs = PayWeekDetailsHistory.joins(:tax_week).where(tax_week_id: tax_week_ids, prospect_id: p_id).order('tax_weeks.date_start asc')
      # Only look for changes if there's more than one history report
      if pwdhs.length > 0
        index = pwdhs.index { |pwdh| pwdh.tax_week_id == tax_week_id }
        if index > 0
          diff = compare_pay_week_detail_histories(pwdhs[index-1], pwdhs[index])
          if diff.length > 0
            changes[p_id] = diff
          end
        end
      end
    end
    changes
  end

  def compare_pay_week_detail_histories(old, new)
    changes = []
    (PayWeekDetailsHistory.attribute_names - %w(id prospect_id tax_week_id created_at updated_at)).each do |attr|
      if old[attr] != new[attr]
        changes || changes = []
        changes << { name: attr, old_value: old[attr], new_value: new[attr]}
      end
    end
    changes
  end

  def remove_unconfirmed_gigs
    if params[:gig_type] == "hired"
      if !params[:tax_week_id].blank?
        tax_week_id = params[:tax_week_id]
        gigs = []
        message = nil
        Gig.where(id: params[:gig_ids]).each do |gig|
          unless gig.gig_tax_weeks.where(tax_week_id: tax_week_id, confirmed: true).exists?
            if PayWeek.where(event_id: gig.event_id, prospect: gig.prospect_id).exists?
              message = 'Some Gigs were not deleted because they have existing Payroll Records'
            else
              gigs << gig
            end
          end
        end
        gigs.each do |gig|
          gig.gig_request.try(:destroy)
          gig.destroy
        end
        if message
          render json: OfficeZoneSync.get_synced_response({message: message})
        else
          render json: OfficeZoneSync.get_synced_response
        end
      else
        render json: {status: 'error', message: 'Please select a tax week'}
      end
    else
      render json: {status: 'error', message: 'Can only remove unconfirmed employees for hired gigs'}
    end
  end

  private

  def increment_event_name(name)
    if name.blank?
      ""
    else
      n = name.scan(/\(([0-9]+)\)/).last
      if n
        n = n.first
        name.gsub("(#{n})", "(#{(n.to_i+1).to_s})")
      else
        name + ' (2)'
      end
    end
  end

  def new_tax_week_cutoff
    Date.today-14
  end

  public

  #*************
  # REPORTS
  #*************

  def download_report
    report = Report.find_by_name(params[:report])

    headers['Cache-Control'] = ''
    headers['Set-Cookie:'] = 'fileDownload=true; path=/'

    case params[:format]
      when 'csv'
        headers['Content-Type'] = "text/csv"
        headers['Content-Disposition'] = "attachment; filename=\"#{report.print_name}.csv\""
        render plain: report.to_csv(params[:ids].split(','))
      when 'xlsx'
        headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        headers['Content-Disposition'] = "attachment; filename=\"#{report.print_name}.xlsx\""
        render plain: report.to_xlsx(params[:ids].split(','))
      when 'pdf'
        headers['Content-Type'] = "application/pdf"
        headers['Content-Disposition'] = "attachment; filename=\"#{report.print_name}.pdf\""
        render plain: report.to_pdf(params[:ids].split(','))
      else
        raise "Unknown Report Format"
    end
  end


  ##############################
  ##### CUSTOM GIG REPORTS #####
  ##############################

  ##### These are very custom reports that don't fit well into what the regular reports were designed for
  ##### It will be much easier to custom-code these than try to adjust the regular reports to accommodate these
  ##### We only need to support excel for these

  class RowTracker
    def initialize(worksheet, header_row_height=0)
      @worksheet = worksheet
      @max_height = 710
      @current_row = -1
      @current_height = 0
      @header_row_height = header_row_height
    end
    def self.default_height
      15
    end
    def default_height
      self.class.default_height
    end
    def next_row(height=self.class.default_height)
      @current_row += 1
      @current_height += height
      @worksheet.set_row(@current_row, height)
      @current_row
    end
    def row
      @current_row
    end
    def page_break
      @worksheet.set_h_pagebreaks(@current_row+1)
      @current_height = @header_row_height
    end
    def page_break_if_needed(height_to_add)
      page_break_added = false
      new_height = @current_height + height_to_add
      if (@current_height + height_to_add) > @max_height
        @worksheet.set_h_pagebreaks(@current_row+1)
        @current_height = [new_height - @max_height, 0].max + @header_row_height
        page_break_added = true
      end
      page_break_added
    end
  end

  def download_custom_registration_sheet                          # with blanks
    event = Event.includes(:assignments).find(params[:event_id])

    ##### FILENAME #####
    filename = event.display_name + "_Reg_Sheet_with_blanks.xlsx"

    io = StringIO.new
    wb = WriteXLSX.new(io)
    format = Report.format_workbook(wb)

    ws = wb.add_worksheet
    gig_assignment_ids = {}
    n = gig_assignment_ids.count + 1

    gig_assignment_ids = params[:gig_assignment_ids].split(',')

    if params[:date].present?
      date = Date.strptime(params[:date], '%d/%m/%Y')
      gig_assignment_ids = GigAssignment.includes(assignment: [:shift]).find(gig_assignment_ids).select {|ga| ga.assignment.shift.date == date}.pluck(:id)
    end

    assignment_ids = GigAssignment.find(gig_assignment_ids).pluck(:assignment_id).uniq

    [4,25,12,10,6,6,28,10,28].each_with_index { |width,i| ws.set_column(i,i,width) }
    ws.write_row(0, 0, ["","Name","Job","Date","Start","End","Location","Tag","Notes"], format[:bold_top])

    GigAssignment.includes([assignment: [:shift, :location, :job], gig: [:prospect, :tags]])
                .where(id: gig_assignment_ids)
                .sort_by { |gig_assignment| [gig_assignment.gig.prospect.last_name,
                                              gig_assignment.gig.prospect.first_name,
                                              gig_assignment.shift.date,
                                              gig_assignment.shift.time_start,
                                              gig_assignment.location.name] }
                .each do |gig_assignment|
      write_reg_sheet_entries(ws, n, gig_assignment, format)
      n+=1
    end

    assignments = Assignment.includes([:job,:shift,:location])
                      .joins(:shift).joins(:event)
                      .where("assignments.event_id = ? AND shifts.tax_week_id = ?", params[:event_id], params[:tax_week_id])
                      .sort_by { |assignment| [assignment.shift.date, assignment.shift.time_start, assignment.location.name] }

    assignments.each do |assignment|
      (assignment.staff_needed - assignment.staff_count).times do
        write_reg_sheet_entries_blanks(ws, n, assignment, format)
        n+=1
      end
    end

    wb.close
    headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render plain: io.string
  end

  def download_custom_registration_sheet_daily                          # with blanks, daily report

    event = Event.includes(:assignments).find(params[:event_id])

    ##### FILENAME #####
    filename = event.display_name + "_Reg_Sheet_with_blanks_daily.xlsx"

    io = StringIO.new
    wb = WriteXLSX.new(io)
    format = Report.format_workbook(wb)
    n = 1

    gig_assignment_ids = params[:gig_assignment_ids].split(',')

    if params[:date].present?
      date = Date.strptime(params[:date], '%d/%m/%Y')
      gig_assignment_ids = GigAssignment.includes(assignment: [:shift]).find(gig_assignment_ids).select {|ga| ga.assignment.shift.date == date}.pluck(:id)
    end

    assignment_ids = GigAssignment.find(gig_assignment_ids).pluck(:assignment_id).uniq

    assignments_by_date = {}
    Assignment.includes(:shift, :location, :job, :event).find(assignment_ids).each do |assignment|
      assignments_by_date[assignment.shift.date] ||= []
      assignments_by_date[assignment.shift.date] << assignment
    end

    assignments_by_date.keys.sort.each do |date|
      n = 1
      if assignments_by_date.keys.length == 1
        ws_title = 'Reg Sheet'
      else
        ws_title = "#{date.to_print.gsub('/', '-')}"
      end
      ws = wb.add_worksheet(ws_title)

      ##### Header and Footer
      header = ''
      header += '&L' + '&13&B' + "Event: #{event.display_name}"
      header += '&R' + '&14&B' + 'Reg Sheet with blanks'
      ws.set_header(header)

      [4,25,12,10,6,6,28,10,28].each_with_index { |width,i| ws.set_column(i,i,width) }
      ws.write_row(0, 0, ["","Name","Job","Date","Start","End","Location","Tag","Notes"], format[:bold_top])

      GigAssignment.includes([assignment: [:shift, :location, :job], gig: [:prospect, :tags]])
                   .where(id: gig_assignment_ids)
                   .sort_by { |gig_assignment| [gig_assignment.gig.prospect.last_name,
                                                gig_assignment.gig.prospect.first_name,
                                                gig_assignment.shift.time_start,
                                                gig_assignment.location.name] }
                  .each do |gig_assignment|
                    if gig_assignment.shift.date = date
                      write_reg_sheet_entries(ws, n, gig_assignment, format)
                      n+=1
                    end
                  end

      assignments = Assignment.includes([:job,:shift,:location])
                              .joins(:shift).joins(:event)
                              .where("assignments.event_id = ? AND shifts.date = ?", params[:event_id], date)
                              .sort_by { |assignment| [assignment.shift.date, assignment.shift.time_start, assignment.location.name] }

      assignments.each do |assignment|
        (assignment.staff_needed - assignment.staff_count).times do
          write_reg_sheet_entries_blanks(ws, n, assignment, format)
          n+=1
        end
      end
    end
    #### Subroutine end here

    wb.close
    headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render plain: io.string
  end

  def write_reg_sheet_entries(ws, n, gig_assignment, format)  # Subroutine for custom reg reports with blanks and custom reg reports with blanks daily
    ws.write_row(n, 0, [n, "#{gig_assignment.gig.prospect.last_name}, #{gig_assignment.gig.prospect.first_name}",
          gig_assignment.job.name,
          gig_assignment.shift.date.strftime('%d/%m/%Y'),
          gig_assignment.shift.time_start.strftime("%H:%M"),
          gig_assignment.shift.time_end.strftime("%H:%M"),
          gig_assignment.location.name,
          gig_assignment.gig.tags.pluck(:name).sort.join(", "),
          gig_assignment.gig.notes
    ], format[:border1])
  end

  def write_reg_sheet_entries_blanks(ws, n, assignment, format)
    ws.write_row(n, 0, [n, "", assignment.job.name,
                              assignment.shift.date.strftime('%d/%m/%Y'),
                              assignment.shift.time_start.strftime("%H:%M"),
                              assignment.shift.time_end.strftime("%H:%M"),
                              assignment.location.name,
                              "",
                              ""
                        ], format[:border1])
  end

  def download_custom_gig_report
    add_page_breaks = params[:page_breaks].present?
    gig_ids = params[:gig_ids].split(',')
    gig_assignment_ids = params[:gig_assignment_ids].split(',')
    if params[:date].present?
      date = Date.strptime(params[:date], '%d/%m/%Y')
      gig_assignment_ids = GigAssignment.includes(assignment: [:shift]).find(gig_assignment_ids).select {|ga| ga.assignment.shift.date == date}.pluck(:id)
    end

    event = Event.find(params[:event_id])
    tax_week = TaxWeek.find(params[:tax_week_id])

    event_clients = EventClient.where(event_id: event.id)

    filename = event.display_name
    dates = if gig_assignment_ids.length > 0
      ##### Put dates in the filename based on the Gig Assignments
      dates = Shift.find(Assignment.find(GigAssignment.find(gig_assignment_ids).pluck(:assignment_id).uniq).pluck(:shift_id).uniq).pluck(:date).uniq.sort
      dates.length == 0 ? [dates.first] : [dates.first, dates.last]
    else
      ##### Put dates in the filename based on the Event Date and TaxWek
      date_start = [event.date_start, tax_week.date_start].max
      date_end =   [event.date_end,   tax_week.date_end  ].min
      date_start == date_end ? [date_start] : [date_start, date_end]
    end
    filename += " (#{dates.first.to_print.gsub('/', ' ')}"
    filename += dates.length > 1 ? " - #{dates.last.to_print.gsub('/', ' ')})" : ')'
    filename += ".xlsx"

    io = StringIO.new
    wb = WriteXLSX.new(io)
    format = Report.format_workbook(wb)

    assignment_ids = GigAssignment.find(gig_assignment_ids).pluck(:assignment_id).uniq
    assignments_by_date = {}
    Assignment.includes(:shift, :location, :job).find(assignment_ids).each do |assignment|
      assignments_by_date[assignment.shift.date] ||= []
      assignments_by_date[assignment.shift.date] << assignment
    end
    gig_assignments_by_assignment_id = {}
    GigAssignment.includes(:assignment, gig: [:prospect]).find(gig_assignment_ids).each do |gig_assignment|
      gig_assignments_by_assignment_id[gig_assignment.assignment.id] ||= []
      gig_assignments_by_assignment_id[gig_assignment.assignment.id] << gig_assignment
    end
    prospects_by_date = {}
    assignments_by_date.keys.sort.each do |date|
      prospects_by_date[date] ||= []
      event_clients.each do |event_client|
        client = event_client.client
        booking = event_client.booking
        on_site_client_contact = booking.client_contact

        ##### Time Sheet
        ##### Max title length is 31 characters
        if assignments_by_date.keys.length == 1
          ws_title = 'Timesheet'
        else
          ws_title = date.to_print.gsub('/', '-')
        end
        ws_title += " (#{client.name.truncate(31-3-ws_title.length, omission: '')})" if event_clients.length > 1
        ws = wb.add_worksheet(ws_title)
        Report.setup_worksheet(ws)
        ws.tab_color = 'yellow'

        ##### Header and Footer
        header = ''
        header += '&L' + '&13&B' + "Client: #{client.name}"
        header += '&R' + '&14&B' + 'Timesheet'
        ws.set_header(header)
        Report.add_standard_footer(ws)

        if params[:type] == 'GoogleEvent'
          [7,4,30,7,7,7,18,4].each_with_index { |width,i| ws.set_column(i,i,width) }
        else
          [4,30,7,7,7,7,18,4].each_with_index { |width,i| ws.set_column(i,i,width) }
        end

        ws.repeat_rows(0,1)
        rt = RowTracker.new(ws, 18+RowTracker.default_height)
        rt.next_row(18)
        if params[:type] == 'GoogleEvent'
          ws.merge_range(rt.row,0,rt.row,2, "Event: #{event.display_name}", format[:bold_top])
          ws.merge_range(rt.row,3,rt.row,4, "Date: #{date.to_print}", format[:date_bold_top])
          ws.merge_range(rt.row,5,rt.row,6, "Location: #{event.location}", format[:bold_top])
          rt.next_row
        else
          ws.merge_range(rt.row,0,rt.row,1, "Event: #{event.display_name}", format[:bold_top])
          ws.merge_range(rt.row,2,rt.row,3, "Date: #{date.to_print}", format[:date_bold_top])
          ws.merge_range(rt.row,5,rt.row,7, "Location: #{event.location}", format[:bold_top])
          rt.next_row
          ws.merge_range(rt.row,0,rt.row,7,'I, the undersigned, confirm the times entered are a correct record of actual times worked at this event contract.', format[:bold_center_smaller_border1_bottom])
        end

        client_signing_height = (2*RowTracker.default_height)+31+18+22+21

        locations = assignments_by_date[date].sort_by {|a| [a.location.name, a.shift.time_start, a.shift.time_end, a.job.name]}.group_by {|a| a.location }
        locations.each_with_index do |(location, assignments), n_location|
          # Google report
          if params[:type] == 'GoogleEvent'
            assignments.each_with_index do |assignment,n_assignment|

              gig_assignments = gig_assignments_by_assignment_id[assignment.id]
              n_blank_assignments = [(assignment.staff_needed - gig_assignments.length), 0].max
              if add_page_breaks
                height_needed = 18*(assignments.length+n_blank_assignments+1)
                height_needed += 18 + client_signing_height if (n_assignment == assignments.length-1)
                rt.page_break_if_needed(height_needed)
              end
              rt.next_row(18)
              ws.write_row(rt.row, 0, %W(Code), format[:field_label_bg_yellow])
              ws.merge_range(rt.row,1,rt.row,2,assignment.to_print_with_staff_count_without_date, format[:field_label_bg_yellow])
              ws.write_row(rt.row, 3, %W(Start End Breaks Comment R), format[:field_label_bg_yellow_bold])

              if rt.row == 3
                ws.write(rt.row,10,'Booked', format[:bold])
              elsif rt.row == 4
                ws.write(rt.row,10,'Worked', format[:bold])
              elsif rt.row == 7
                ws.merge_range(rt.row,10,rt.row,11,'Daily Shift Pin', format[:bold_red_size_12])
              elsif rt.row == 10
                ws.write(rt.row,10,'Shift Rep', format[:bold])
              end

              n = 1
              gig_assignments.each_with_index do |gig_assignment|
                rt.next_row(18)

                if rt.row == 3
                  ws.write(rt.row,10,'Booked', format[:bold])
                elsif rt.row == 4
                  ws.write(rt.row,10,'Worked', format[:bold])
                elsif rt.row == 7
                  ws.merge_range(rt.row,10,rt.row,11,'Daily Shift Pin', format[:bold_red_size_12])
                elsif rt.row == 10
                  ws.write(rt.row,10,'Shift Rep', format[:bold])
                end
                ws.write_row(rt.row, 0, ["#{gig_assignment.gig.prospect.test_site_code}"], format[:border1])
                ws.write_row(rt.row, 1, [n, "#{gig_assignment.gig.prospect.last_name}, #{gig_assignment.gig.prospect.first_name}"], format[:border1])
                ws.write_row(rt.row, 3, [assignment.shift.time_start.strftime("%H:%M"),'','','',''], format[:border1])
                prospects_by_date[date] << gig_assignment.gig.prospect unless prospects_by_date[date].include? gig_assignment.gig.prospect
                n+=1
              end
              n_blank_assignments.times do
                rt.next_row(18)

                if rt.row == 3
                  ws.write(rt.row,10,'Booked', format[:bold])
                elsif rt.row == 4
                  ws.write(rt.row,10,'Worked', format[:bold])
                elsif rt.row == 7
                  ws.merge_range(rt.row,10,rt.row,11,'Daily Shift Pin', format[:bold_red_size_12])
                elsif rt.row == 10
                  ws.write(rt.row,10,'Shift Rep', format[:bold])
                end
                ws.write_row(rt.row, 1, [n,''],format[:border1])
                ws.write_row(rt.row, 3, [assignment.shift.time_start.strftime("%H:%M"),'','','',''], format[:border1])
                n+=1
              end
            end
          else
            assignments.each_with_index do |assignment,n_assignment|
              gig_assignments = gig_assignments_by_assignment_id[assignment.id]
              n_blank_assignments = [(assignment.staff_needed - gig_assignments.length), 0].max
              if add_page_breaks
                height_needed = 18*(assignments.length+n_blank_assignments+1)
                height_needed += 18 + client_signing_height if (n_assignment == assignments.length-1)
                rt.page_break_if_needed(height_needed)
              end
              rt.next_row(18)
              ws.merge_range(rt.row,0,rt.row,1,assignment.to_print_with_staff_count_without_date, format[:field_label_bg_yellow])
              ws.write_row(rt.row, 2, %W(Start End Breaks Total Sign R), format[:field_label_bg_yellow_bold])
              n = 1
              gig_assignments.each_with_index do |gig_assignment|
                rt.next_row(18)
                ws.write_row(rt.row, 0, [n, "#{gig_assignment.gig.prospect.last_name}, #{gig_assignment.gig.prospect.first_name}"], format[:border1])
                ws.write_row(rt.row, 2, [assignment.shift.time_start.strftime("%H:%M"),'','','','',''], format[:border1])
                prospects_by_date[date] << gig_assignment.gig.prospect unless prospects_by_date[date].include? gig_assignment.gig.prospect
                n+=1
              end
              n_blank_assignments.times do
                rt.next_row(18)
                ws.write_row(rt.row, 0, [n,''],format[:border1])
                ws.write_row(rt.row, 2, [assignment.shift.time_start.strftime("%H:%M"),'','','','',''], format[:border1])
                n+=1
              end
            end
          end

          if add_page_breaks
            add_blank_assignment_section(ws, rt, format, params[:type], add_page_breaks)
            rt.next_row
            rt.page_break_if_needed(client_signing_height)
            insert_client_signing_box(ws, rt, event, client, booking, format)
            rt.page_break unless n_location == locations.length-1
          end
        end

        unless add_page_breaks
          add_blank_assignment_section(ws, rt, format, params[:type], add_page_breaks)
          rt.next_row
          rt.next_row
          if params[:type] != 'GoogleEvent'
            insert_client_signing_box(ws, rt, event, client, booking, format)
          end
        end

        if params[:type] == 'small'
           ##### Telephone List
           rt.page_break_if_needed(rt.default_height*(prospects_by_date[date].length+1)) if add_page_breaks
           rt.next_row
           rt.next_row
           ws.write_row(rt.row,0,['','Name', 'Mobile', 'Emergency'], format[:field_label])
           ws.merge_range(rt.row,2,rt.row,3,'Mobile', format[:field_label])
           ws.merge_range(rt.row,4,rt.row,5,'Emergency', format[:field_label])
           rt.next_row
           prospects_by_date[date].sort_by {|p| [p.last_name, p.first_name]}.each_with_index do |prospect,i|
             ws.write_row(rt.row,0,[i+1, "#{prospect.last_name}, #{prospect.first_name}"], format[:border1])
             ws.merge_range(rt.row,2,rt.row,3,Report.format_phone(prospect.mobile_no), format[:border1])
             ws.merge_range(rt.row,4,rt.row,5,Report.format_phone(prospect.emergency_no), format[:border1])
             rt.next_row
           end
        end

        if params[:type] == 'GoogleEvent'
          ##### Telephone List
          rt.page_break_if_needed(rt.default_height*(prospects_by_date[date].length+1)) if add_page_breaks
          rt.next_row
          rt.next_row
          ws.merge_range(rt.row,0,rt.row,6,'All telephone numbers below are for the sole use of staffing management.', format[:bold_center])
          rt.next_row
          ws.merge_range(rt.row,0,rt.row,6,'At no point should numbers be shared without the consent of the individual', format[:bold_center])
          rt.next_row
          ws.write(rt.row,0,'', format[:field_label_bg_yellow_bold_center])
          ws.merge_range(rt.row,1,rt.row,2,'Name', format[:field_label_bg_yellow_bold_center])
          ws.merge_range(rt.row,3,rt.row,4,'Mobile', format[:field_label_bg_yellow_bold_center])
          ws.merge_range(rt.row,5,rt.row,6,'Emergency', format[:field_label_bg_yellow_bold_center])
          rt.next_row
          prospects_by_date[date].sort_by {|p| [p.last_name, p.first_name]}.each_with_index do |prospect,i|
            ws.write_row(rt.row,0,[i+1], format[:border1])
            ws.merge_range(rt.row,1,rt.row,2,"#{prospect.last_name}, #{prospect.first_name}", format[:border1])
            ws.merge_range(rt.row,3,rt.row,4,Report.format_phone(prospect.mobile_no), format[:border1])
            ws.merge_range(rt.row,5,rt.row,6,Report.format_phone(prospect.emergency_no), format[:border1])
            rt.next_row
          end
        end
      end
    end

    if params[:type] == 'medium' || params[:type] == 'large'
      report = Report.find_by_name('tel_no')
      report.add_xlsx_worksheets(wb, gig_ids, format, 'green')
    end

    if gig_assignment_ids.length > 0 && params[:type] != 'GoogleEvent'
      report = Report.find_by_name('reg_sheet')
      report.add_xlsx_worksheets(wb, gig_assignment_ids, format, 'red')
    end

    if params[:type] == 'large' && gig_assignment_ids.length > 0
      ##### Break Sheets
      assignments_by_date.keys.sort.each do |date|
        event_clients.each do |event_client|
          client = event_client.client
          if assignments_by_date.keys.length == 1
            ws_title = 'Break Sheet'
          else
            ws_title = "BS #{date.to_print.gsub('/', '-')}"
          end
          ##### Max title length is 31 characters
          ws_title += " (#{client.name.truncate(31-3-ws_title.length, omission: '')})" if event_clients.length > 1
          ws = wb.add_worksheet(ws_title)
          Report.setup_worksheet(ws)
          ws.tab_color = 'blue'

          ##### Header and Footer
          header = ''
          header += '&L' + '&13&B' + "Client: #{client.name}"
          header += '&R' + '&14&B' + 'Break Sheet'
          ws.set_header(header)
          Report.add_standard_footer(ws)

          [4,30,8,8,8,8,8,8].each_with_index { |width,i| ws.set_column(i,i,width) }

          rt = RowTracker.new(ws)

          locations = assignments_by_date[date].sort_by {|a| [a.location.name, a.shift.time_start, a.shift.time_end, a.job.name]}.group_by {|a| a.location }
          locations.each_with_index do |(location, assignments), n_location|
            rt.next_row(18)
            ws.merge_range(rt.row,0,rt.row,1, "Event: #{event.display_name}", format[:bold_top])
            ws.merge_range(rt.row,2,rt.row,3, "Date: #{date.to_print}",      format[:date_bold_top])
            ws.merge_range(rt.row,5,rt.row,7, "Location: #{location.name}",  format[:bold_top])
            rt.next_row
            ws.merge_range(rt.row,0,rt.row,7,'I, the undersigned, acknowledge the breaks away from my work area as stated below.', format[:bold_center_smaller_border1_bottom])
            rt.next_row
            ws.merge_range(rt.row,0,rt.row+1,0,'', format[:field_label_bg_yellow_bold_center])
            ws.merge_range(rt.row,1,rt.row+1,1,'Name', format[:field_label_bg_yellow_bold_center])
            ws.merge_range(rt.row,2,rt.row,4,'First Break', format[:field_label_bg_yellow_bold_center_with_border2_right])
            ws.merge_range(rt.row,5,rt.row,7,'Second Break', format[:field_label_bg_yellow_bold_center_with_border2_left])
            rt.next_row
            ws.write(rt.row,2,'Out', format[:field_label_bg_yellow_bold_center])
            ws.write(rt.row,3,'In',  format[:field_label_bg_yellow_bold_center])
            ws.write(rt.row,4,'Sign',format[:field_label_bg_yellow_bold_center_with_border2_right])
            ws.write(rt.row,5,'Out', format[:field_label_bg_yellow_bold_center_with_border2_left])
            ws.write(rt.row,6,'In',  format[:field_label_bg_yellow_bold_center])
            ws.write(rt.row,7,'Sign',format[:field_label_bg_yellow_bold_center])

            prospects_by_date[date] = []
            assignments.each_with_index do |assignment,n_assignment|
              gig_assignments = gig_assignments_by_assignment_id[assignment.id].each_with_index do |gig_assignment|
                prospects_by_date[date] << gig_assignment.gig.prospect unless prospects_by_date[date].include? gig_assignment.gig.prospect
              end
            end

            prospects_by_date[date].sort_by {|p| [p.last_name, p.first_name]}.each_with_index do |prospect,i|
              rt.next_row(18)
              ws.write_row(rt.row,0,[i+1, "#{prospect.last_name}, #{prospect.first_name}", '', ''], format[:border1])
              ws.write(rt.row,4,'',format[:border1_with_border2_right])
              ws.write(rt.row,5,'',format[:border1_with_border2_left])
              ws.write_row(rt.row,6, ['',''], format[:border1])
            end

            3.times do
              rt.next_row(18)
              ws.write_row(rt.row,0,['', '', '', ''], format[:border1])
              ws.write(rt.row,4,'',format[:border1_with_border2_right])
              ws.write(rt.row,5,'',format[:border1_with_border2_left])
              ws.write_row(rt.row,6, ['',''], format[:border1])
            end

            if add_page_breaks
              rt.page_break unless n_location == locations.length-1
            else
              rt.next_row
            end
          end
        end
      end

      ##### Sign-in / Cash Declaration
      assignments_by_date.keys.sort.each do |date|
        event_clients.each do |event_client|
          client = event_client.client
          if assignments_by_date.keys.length == 1
            ws_title = 'Sign In'
          else
            ws_title = "SI #{date.to_print.gsub('/', '-')}"
          end
          ##### Max title length is 31 characters
          ws_title += " (#{client.name.truncate(31-3-ws_title.length, omission: '')})" if event_clients.length > 1
          ws = wb.add_worksheet(ws_title)
          Report.setup_worksheet(ws)
          ws.tab_color = 'orange'

          ##### Header and Footer
          header = ''
          header += '&L' + '&13&B' + "Client: #{client.name}"
          header += '&R' + '&14&B' + 'Staff Sign In / Cash Declaration'
          ws.set_header(header)
          Report.add_standard_footer(ws)

          [4,30,10,10,21,10].each_with_index { |width,i| ws.set_column(i,i,width) }

          rt = RowTracker.new(ws)

          locations = assignments_by_date[date].sort_by {|a| [a.location.name, a.shift.time_start, a.shift.time_end, a.job.name]}.group_by {|a| a.location }
          locations.each_with_index do |(location, assignments), n_location|
            rt.next_row(18)
            ws.merge_range(rt.row,0,rt.row,1, "Event: #{event.display_name}", format[:bold_top])
            ws.merge_range(rt.row,2,rt.row,3, "Date: #{date.to_print}",      format[:date_bold_top])
            ws.merge_range(rt.row,4,rt.row,5, "Location: #{location.name}",  format[:bold_top])
            rt.next_row(50)
            ws.merge_range(rt.row,0,rt.row,5,"I, the undersigned, confirm that all personal money and personal bags and belongings on site have been declared below. Anyone drawing money from ATM, cash points during the shift or while on a break are expected to get a receipt and declare. My declaration is evidence during spot searches. I acknowledge #{client.name}'s right to ethical and document search.", format[:bold_center_smaller_border1_bottom])
            rt.next_row(40)
            ws.write_row(rt.row,0,['','Name'], format[:field_label_bg_yellow_bold])
            ws.write_row(rt.row,2,['Amount Declared','# Bags','Sign to verify & Acknowledge TBC Events Search Policy','Job'], format[:field_label_bg_yellow_bold_center])

            prospects_by_date = {}
            prospects_by_date[date] = []
            jobs_for_prospect_by_date = {}
            jobs_for_prospect_by_date[date] = {}
            assignments.each_with_index do |assignment,n_assignment|
              gig_assignments = gig_assignments_by_assignment_id[assignment.id].each_with_index do |gig_assignment|
                prospect = gig_assignment.gig.prospect
                prospects_by_date[date] << prospect unless prospects_by_date[date].include? prospect
                jobs_for_prospect_by_date[date][prospect.id] ||= []
                job_name = gig_assignment.assignment.job.name
                jobs_for_prospect_by_date[date][prospect.id] << job_name unless jobs_for_prospect_by_date[date][prospect.id].include? job_name
              end
            end

            prospects_by_date[date].sort_by {|p| [p.last_name, p.first_name]}.each_with_index do |prospect,i|
              rt.next_row(18)
              ws.write_row(rt.row,0,[i+1, "#{prospect.last_name}, #{prospect.first_name}", '', '','',jobs_for_prospect_by_date[date][prospect.id].sort.join(', ')], format[:border1])
            end

            3.times do
              rt.next_row(18)
              ws.write_row(rt.row,0,['','','','','',''], format[:border1])
            end

            if add_page_breaks
              rt.page_break unless n_location == locations.length-1
            else
              rt.next_row
            end
          end
        end
      end


    end

    wb.close
    headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    render plain: io.string
  end

  def add_blank_assignment_section(ws, rt, format, type, add_page_breaks)
    n_blank_assignments = case type
                          when 'medium', 'large'
                            4
                          when 'small'
                            2
                          when 'GoogleEvent'
                            2
                          else
                            2
                          end
    rt.page_break_if_needed(18*(n_blank_assignments+1)) if add_page_breaks
    rt.next_row(18)
    if type == 'GoogleEvent'
      ws.merge_range(rt.row,0,rt.row,2,'', format[:field_label_bg_yellow])
      ws.write_row(rt.row, 3, %W(Start End Breaks Comment R), format[:field_label_bg_yellow_bold])

      n_blank_assignments.times do
        rt.next_row(18)

        if rt.row == 3
          ws.write(rt.row,10,'Booked', format[:bold])
        elsif rt.row == 4
          ws.write(rt.row,10,'Worked', format[:bold])
        elsif rt.row == 7
          ws.merge_range(rt.row,10,rt.row,11,'Daily Shift Pin', format[:bold_red_size_12])
        elsif rt.row == 10
          ws.write(rt.row,10,'Shift Rep', format[:bold])
        end

        ws.write_row(rt.row, 0, ['', '', ''], format[:border1])
        ws.write_row(rt.row, 3, ['','','','',''], format[:border1])
      end

      while rt.row <= 10
        rt.next_row(18)

        if rt.row == 3
          ws.write(rt.row,10,'Booked', format[:bold])
        elsif rt.row == 4
          ws.write(rt.row,10,'Worked', format[:bold])
        elsif rt.row == 7
          ws.merge_range(rt.row,10,rt.row,11,'Daily Shift Pin', format[:bold_red_size_12])
        elsif rt.row == 10
          ws.write(rt.row,10,'Shift Rep', format[:bold])
        end

        ws.write_row(rt.row, 0, ['', '', ''], format[:border1])
        ws.write_row(rt.row, 3, ['','','','',''], format[:border1])
      end
    else
      ws.merge_range(rt.row,0,rt.row,1,'', format[:field_label_bg_yellow])
      ws.write_row(rt.row, 2, %W(Start End Breaks Total Sign R), format[:field_label_bg_yellow_bold])

      n_blank_assignments.times do
        rt.next_row(18)
        ws.write_row(rt.row, 0, ['', ''], format[:border1])
        ws.write_row(rt.row, 2, ['','','','','',''], format[:border1])
      end
    end
  end

  def insert_client_signing_box(ws, rt, event, client, booking, format)
    flair_client_contact = ClientContact.find_by_id(event.leader_client_contact_id) || nil
    on_site_client_contact = booking.client_contact
    ##### Event Information
    ws.merge_range(rt.row,0,rt.row,3, '', format[:standard])
    ws.write_rich_string(rt.row,0, format[:bold], 'On Site Contact(s):', format[:standard], " #{on_site_client_contact ? "#{on_site_client_contact.first_name} #{on_site_client_contact.last_name}  #{on_site_client_contact.mobile_no}" : ''}")
    ws.merge_range(rt.row,4,rt.row,7, '', format[:standard])
    ws.write_rich_string(rt.row,4, format[:bold], 'Flair Contact:', format[:standard], " #{flair_client_contact ? "#{flair_client_contact.first_name} #{flair_client_contact.last_name}  #{flair_client_contact.mobile_no}" : ''}")
    rt.next_row
    ws.merge_range(rt.row,0,rt.row,3, "Number of Staff Required: #{event.staff_needed}", format[:bold])
    ws.merge_range(rt.row,4,rt.row,7, "Number of Staff Working:", format[:bold])

    rt.next_row(31)

    if params[:type] == 'GoogleEvent'
      ws.merge_range(rt.row,0,rt.row,8, '', format[:border2_top_left_right])
      ws.write_rich_string(rt.row,0, format[:bold], "Client: #{client.name}:", format[:standard], ' I certify that the total number of staff shown, and their working hours, as indicated on this timesheet, are correct and to be invoiced according to our terms of business.', format[:border2_top_left_right])
    else
      ws.merge_range(rt.row,0,rt.row,7, '', format[:border2_top_left_right])
      ws.write_rich_string(rt.row,0, format[:bold], "Client: #{client.name}:", format[:standard], ' I certify that the total number of staff shown, and their working hours, as indicated on this timesheet, are correct and to be invoiced according to our terms of business.', format[:border2_top_left_right])
    end

    rt.next_row(18)
    ws.write(rt.row,0,'',format[:border2_left])

    if params[:type] == 'GoogleEvent'
      ws.merge_range(rt.row,1,rt.row,2,"Signature:", format[:standard])
      ws.merge_range(rt.row,4,rt.row,5,"Print Name:", format[:standard])
      ws.write(rt.row,7,"Position:", format[:standard])
      ws.write(rt.row,8,"", format[:border2_right])
    else
      ws.write(rt.row,1,"Signature:", format[:standard])
      ws.merge_range(rt.row,3,rt.row,4,"Print Name:", format[:standard])
      ws.write(rt.row,6,"Position:", format[:standard])
      ws.write(rt.row,7,'',format[:border2_right])
    end

    rt.next_row(22)
    ws.write(rt.row,0,'', format[:border2_left])

    if params[:type] == 'GoogleEvent'
      ws.merge_range(rt.row,1,rt.row,2,'', format[:border1_bottom])
      ws.merge_range(rt.row,4,rt.row,5, '', format[:border1_bottom])
      ws.write(rt.row,7,'', format[:border1_bottom])
      ws.write(rt.row,8,'', format[:border2_right])
    else
      ws.write(rt.row,1,'', format[:border1_bottom])
      ws.merge_range(rt.row,3,rt.row,4, '', format[:border1_bottom])
      ws.write(rt.row,6,'', format[:border1_bottom])
      ws.write(rt.row,7,'', format[:border2_right])
    end

    rt.next_row(21)
    ws.merge_range(rt.row,0,rt.row,4,"Please note the minimum charge of #{booking.minimum_hours || '__'} hours for each staff member", format[:border2_bottom_left])
    ws.write(rt.row,5,'Date:', format[:border2_bottom])
    ws.write(rt.row,6,'',format[:border2_bottom])

    if params[:type] == 'GoogleEvent'
      ws.write(rt.row,7,'',format[:border2_bottom])
      ws.write(rt.row,8,'',format[:border2_bottom_right])
    else
      ws.write(rt.row,7,'',format[:border2_bottom_right])
    end
  end

  #############################
  ##### Special Downloads #####
  #############################

  # Some events require special deliverables of ids, photos, etc. Yuck!

  def download_accreditation
    # We use accredited tag to track what we process.
    tag_value = 'Accredited'
    event_id = params[:event_id]
    accredited_tag = Tag.where(event_id: event_id, name: tag_value).first_or_initialize
    accredited_tag.save
    already_accredited_gig_ids = accredited_tag.gig_tags.pluck(:id)
    gigs = Gig.where(id: params[:gig_ids]) #.where.not(id: already_accredited_gig_ids)

    zip_path = Tempfile.new("accrediation.zip")
    photo_name = {}
    missing_photos = []


    Dir.mktmpdir('accrediation') do |dir|
      paths = []
      photos_dir = File.join(dir, 'photos')
      FileUtils.mkdir_p(photos_dir)
      gigs.each do |gig|
        p = gig.prospect
        if p.photo.present?
          photo_path_src = File.join(Flair::Application.config.shared_dir, 'prospect_photos', p.photo)
          if File.exists?(photo_path_src)
            photo_name[p.id] = "#{p.first_name}.#{p.last_name}#{File.extname(p.photo)}"
            photo_path_dest =  File.join(photos_dir, photo_name[p.id])
            FileUtils.cp(photo_path_src, photo_path_dest)
            paths << {path: photo_path_dest, name: 'photos/'+photo_name[p.id]}
          else
            missing_photos << p.id
            photo_name[p.id] = ""
          end
        else
          missing_photos << p.id
        end
      end

      rows = []
      import_xlsx_path = File.join(dir, 'ImportTemplate.xlsx')
      workbook = WriteXLSX.new(import_xlsx_path)
      worksheet = workbook.add_worksheet
      value_pairs = []
      # value_pairs << {col: 'FIRST_NAME',         value: lambda {|p| p.first_name}}
      # value_pairs << {col: 'SURNAME',            value: lambda {|p| p.last_name}}
      # value_pairs << {col: 'PREVIOUS_SURNAME',   value: ''}
      # value_pairs << {col: 'GENDER',             value: lambda {|p| {nil: '', 'M' => 'Male', 'F' => 'Female'}[p.gender]}}
      # value_pairs << {col: 'DATE OF BIRTH',      value: lambda {|p| p.date_of_birth.try(:strftime, '%d/%m/%Y')}}
      # value_pairs << {col: 'TOWN/CITY OF BIRTH', value: ''}
      # value_pairs << {col: 'NATIONALITY',        value: lambda {|p| p.nationality.try(:name)}}
      # value_pairs << {col: 'ORGANISATION',       value: ''}
      # value_pairs << {col: 'JOB TITLE',          value: ''}
      # value_pairs << {col: 'CONTACT NUMBER',     value: lambda {|p| (p.mobile_no.present? && p.mobile_no) || (p.phone_no.present? && p.home_no) || ''}}
      # value_pairs << {col: 'EMAIL ADDRESS',      value: lambda {|p| p.email}}
      # value_pairs << {col: 'Current ADDRESS 1',  value: lambda {|p| p.address}}
      # value_pairs << {col: 'Current ADDRESS 2',  value: lambda {|p| p.address2}}
      # value_pairs << {col: 'Current ADDRESS 3',  value: ''}
      # value_pairs << {col: 'TOWN/ CITY',         value: lambda {|p| p.city}}
      # value_pairs << {col: 'POST/ ZIP CODE',     value: lambda {|p| p.post_code}}
      # value_pairs << {col: 'COUNTRY',            value: 'United Kingdom'}
      # value_pairs << {col: 'Venue?/ Location',   value: ''}
      # value_pairs << {col: 'IMAGE FILENAME',     value: lambda {|p| photo_name[p.id]}}
      # value_pairs << {col: 'FUNCTION',           value: 'Venue'}
      # value_pairs << {col: 'CATEGORY',           value: 'Catering'}
      # value_pairs << {col: 'SUB CATEGORY',       value: 'Head of Catering'}
      # value_pairs << {col: 'AGREE TO TERMS AND CONDITIONS', value: 'Yes'}

      value_pairs << {col: 'Organisation identification number',         value: ''}
      value_pairs << {col: 'Main Function',            value: gigs.last&.job&.name.nil? ? '' : gigs.last&.job&.name }
      value_pairs << {col: 'Preferred Given Name',   value: 'Joe'}
      value_pairs << {col: 'Preferred Family Name',             value: 'Bloggs'}
      value_pairs << {col: 'Email Address',      value: lambda {|p| p.email}}
      value_pairs << {col: 'Telepone Number', value: lambda {|p| (p.mobile_no.present? && p.mobile_no) || (p.phone_no.present? && p.home_no) || ''}}
      value_pairs << {col: 'Address Line 1',        value: lambda {|p| p.address}}
      value_pairs << {col: 'Address Line 2',       value: lambda {|p| p.address2}}
      value_pairs << {col: 'Address Line 3',          value: ''}
      value_pairs << {col: 'Town of Residence',     value: ''}
      value_pairs << {col: 'Country of Residence',      value: lambda {|p| p.country}}
      value_pairs << {col: 'Postcode/Zipcode', value: lambda {|p| p.post_code}}
      value_pairs << {col: 'Do you have any accessibility requirements?',  value: 'Yes'}
      value_pairs << {col: 'Employee source',  value: 'They were an existing employee'}
      value_pairs << {col: 'Are you a UK national?',         value: (p.nationality.name == "United Kingdom" ? "Yes" : "No")}
      value_pairs << {col: 'Identification Type',     value: lambda {|p| p.id_type}}
      value_pairs << {col: 'Passport upload filename',            value: ''}
      value_pairs << {col: 'UK identification document filename',   value: ''}
      value_pairs << {col: 'Document given names',     value: 'Joe'}
      value_pairs << {col: 'Document family names',           value: 'Bloggs'}
      value_pairs << {col: 'Do you have a previous family name?',           value: ''}
      value_pairs << {col: 'Previous family names',       value: 'Jameson'}
      value_pairs << {col: 'DATE OF BIRTH', value: lambda {|p| p.date_of_birth.try(:strftime, '%d/%m/%Y')}}
      value_pairs << {col: 'Document Gender', value: lambda {|p| {nil: '', 'M' => 'Male', 'F' => 'Female'}[p.gender]}}
      value_pairs << {col: 'Nationality', value: lambda {|p| p.nationality.name}}
      value_pairs << {col: 'Identification Number', value: lambda {|p| p.etihad_id_number.to_s+"_ID"}}
      value_pairs << {col: 'Document Expiration Date', value: ''}
      value_pairs << {col: 'Country of Document issue', value: ''}
      value_pairs << {col: 'Place of BIRTH', value: ''}
      value_pairs << {col: 'Country of BIRTH', value: ''}
      value_pairs << {col: 'Applicant photo upload', value: ''}
      value_pairs << {col: 'Have you read and accepted the privacy notice and games management system terms and conditions?', value: ''}
      value_pairs << {col: 'Have you read and accepted the cookies policy?', value: ''}
      value_pairs << {col: 'Affiliated organisation', value: ''}

      rows << value_pairs.map {|value_pair| value_pair[:col]}

      gigs.each do |gig|
        p = gig.prospect
        row = []
        value_pairs.each do |value_pair|
          row << (value_pair[:value].respond_to?(:call) ? value_pair[:value].call(p) : value_pair[:value])
        end
        rows << row
      end

      widths = []
      rows.each do |row|
        row.each_with_index do |value, i|
          widths[i] = [widths[i]||0, value.to_s.length].max
        end
      end

      widths.each_with_index do |width, c|
        worksheet.set_column(c,c,width)
      end

      r = 0
      rows.each do |row|
        worksheet.write_row(r,0,row)
        r += 1
      end
      paths << {path: import_xlsx_path, name: "ICC Accred Excel #{DateTime.now.strftime('%d-%m-%y')}.xlsx"}
      workbook.close

      temp_zip_path = File.join(dir, 'accreditation.zip')
      Zip::File.open(temp_zip_path, Zip::File::CREATE) do |zf|
        paths.each do |path|
          zf.add(path[:name], path[:path])
        end
      end
      FileUtils.cp(temp_zip_path, zip_path)
    end
    gigs.select {|gig| photo_name[gig.prospect_id]}.each do |gig|
      gig_tag = GigTag.where(gig_id: gig.id, tag_id: accredited_tag.id).first_or_initialize
      gig_tag.save
    end

    # send_file(zip_path, disposition: 'attachment', filename: 'accreditation.zip')
    zip_filename = "Accreditation-FlairEvents-#{DateTime.now.try(:strftime, '%d/%m/%Y')}.zip"
    send_file(zip_path, disposition: 'attachment', filename: zip_filename)

  end

  def download_etihad_package

    # etihad_event_ids = [2276, #Eti. Ed Sheeran
    #                     2277, #Eti. Taylor Swift
    #                     2314, #Eti. Beyonce & Jay Z
    #                     2278] #Eti. Foo Fighters
    etihad_event_ids = [3920, #Etihad Liam Gallagher
                        3921] #Etihad - Ed Sheeran

    raise "Invalid Event!" unless etihad_event_ids.include?(params[:event_id].to_i)

    # subtract_event_ids = {
    #   2276 => [],
    #   2277 => [2276],
    #   2314 => [2276,2277],
    #   2278 => [2276,2277,2314]
    # }
    subtract_event_ids = {
      3920 => [],
      3921 => [3920]
    }

    event_id = params[:event_id].to_i
    event = Event.find event_id

    etihad_photo_name = {}
    etihad_pdf_name = {}
    missing_ids = []
    missing_photos = []

    create_photos = true
    create_ids = true
    create_import_spreadsheet = true
    create_allocation_spreadsheet = true

    ##### Get all prospects associated with these events
    # event_id = '3920'
    gigs = Gig.where(event_id: event_id)
    prospect_ids = Gig.where(event_id: event_id).pluck(:prospect_id).uniq
    prospect_ids_subtract = Gig.where(event_id: subtract_event_ids[event_id]).pluck(:prospect_id).uniq

    prospects = (prospect_ids - prospect_ids_subtract).map {|id| Prospect.find(id)}

    ##### Map their IDs to Etihad IDs. Take the last 4 digits of their ID, if non-unique, modify it
    prospects.each do |p|
      unless p.etihad_id_number
        new_id =  ("742" + p.id.to_s[-4..-1]).to_i
        iterations = 0
        while Prospect.where(etihad_id_number: new_id).exists?
          iterations += 1
          raise "Ran out of IDs!" if iterations > 1000000
          new_id = (new_id == 7429999) ? 742000000 : new_id + 1
        end
        p.etihad_id_number = new_id
        p.save
      end
    end

    zip_filename = "Etihad-FlairEvents-#{DateTime.now.try(:strftime, '%d/%m/%Y')}.zip"
    zip_path = Tempfile.new("etihad.zip")
    Dir.mktmpdir('etihad') do |dir|
      paths = []

      if create_photos
        photos_dir = File.join(dir, 'photos')
        FileUtils.mkdir_p(photos_dir)
        prospects.each do |p|
          if p.photo.present?
            photo_path_src = File.join(Flair::Application.config.shared_dir, 'prospect_photos', p.photo)
            if File.exists?(photo_path_src)
              etihad_photo_name[p.id] = "#{p.etihad_id_number}_PHOTO#{File.extname(p.photo)}"
              photo_path_dest =  File.join(photos_dir, etihad_photo_name[p.id])
              FileUtils.cp(photo_path_src, photo_path_dest)
              paths << {path: photo_path_dest, name: 'photos/'+etihad_photo_name[p.id]}
            else
              missing_photos << p.id
              etihad_photo_name[p.id] = ""
            end
          else
            missing_photos << p.id
          end
        end
      end

      if create_ids
        ids_dir = File.join(dir, 'ids')
        FileUtils.mkdir_p(ids_dir)
        #A4 size - 0.5in margins
        a4_width = 595.28 - 2*36
        a4_height = 841.89 - 2*36
        photo_size_4 = [a4_width/2, a4_height/2 ]
        photo_size_2 = [a4_width, a4_height/2]
        #top-left-corners
        photo_locations_2 = {
          0 => [0,a4_height],
          1 => [0,a4_height/2]
        }
        photo_locations_4 = {
          0 => [0,a4_height],
          1 => [a4_width/2,a4_height],
          2 => [0,a4_height/2],
          3 => [a4_width/2, a4_height/2]
        }

        prospects.each do |p|
          scanned_ids = ScannedId.where(prospect_id: p.id)
          if scanned_ids.length > 0
            if scanned_ids.length > 2
              photo_location = photo_locations_4
              photo_size = photo_size_4
            else
              photo_location = photo_locations_2
              photo_size = photo_size_2
            end
            etihad_pdf_name[p.id] = "#{p.etihad_id_number}_ID.pdf"
            pdf_path = File.join(ids_dir, etihad_pdf_name[p.id])
            pdf_okay = true
            pdf = Prawn::Document.new(page_size: 'A4')
            pdf_files = []
            scanned_ids.each_with_index do |scanned_id, i|
              if scanned_id.photo.split('.').last == 'pdf'
                pdf_path = File.join(Flair::Application.config.shared_dir, 'scanned_ids', scanned_id.photo)
                if File.exists?(pdf_path)
                  pdf_files << pdf_path
                else
                  pdf_okay = false
                end
              else
                image_path = File.join(Flair::Application.config.shared_dir, 'scanned_ids_large', scanned_id.photo)
                if File.exists?(image_path)
                  orig_size = FastImage.size(image_path)
                  if orig_size[0] < orig_size[1] && photo_size[0] > photo_size[1] || orig_size[0] > orig_size[1] && photo_size[0] < photo_size[1]
                    pdf.rotate 90, origin: photo_location[i]  do
                      pdf.image image_path, {fit: [photo_size[1], photo_size[0]], at: [photo_location[i][0]-photo_size[1], photo_location[i][1]]}
                    end
                  else
                    pdf.image image_path, {fit: photo_size, at: photo_location[i]}
                  end
                else
                  pdf_okay = false
                end
              end
            end
            if p.share_code_files.count > 0
              path = File.join(Flair::Application.config.shared_dir, 'prospect_share_codes', p.share_code_files.last.path) 
              if File.exists?(path)
                pdf_files << path
              end
            end

            pdf_files.each do |path|
              PDF::Reader.new(path).page_count.times.each do |index|
                pdf.start_new_page(template: path, template_page: index + 1)
              end
            end
            if pdf_okay
              pdf.render_file(pdf_path)
              paths << {path: pdf_path, name: 'ids/'+etihad_pdf_name[p.id]}
            else
              missing_ids << p.id
              etihad_pdf_name[p.id] = ""
            end
          else
            missing_ids << p.id
            etihad_pdf_name[p.id] = ""
          end
        end
      end

      if create_import_spreadsheet
        rows = []
        import_xlsx_path = File.join(dir, 'ImportTemplate.xlsx')
        workbook = WriteXLSX.new(import_xlsx_path)
        worksheet = workbook.add_worksheet
        # rows << ['First Name', 'Surname', 'Email Address', 'Job Title', 'Gender', 'Organisation', 'Employee ID Number', 'Date of Birth', 'Event to register to', 'Function', 'Category', 'Sub Category', 'passport filename', 'Nationality (Country)', 'ID number', 'Expiry Date', 'Country of Issue / Country of Birth', 'Visa Issue Date', 'Visa Expiry Date', 'Indefinite Leave', 'Image Filename', 'Agree to Terms and Conditions']
        rows << ['Last Name',
          'First name',
          'Date of Birth',
          'Email Address',
          'Mobile Country Code',
          'Mobile Number',
          'Job Title',
          'ROLE',
          'Organisation',
          'Employee ID Number',
          'Headshot Photo (Filename)',
          'Terms and Conditions',
          'Country of Nationality',
          'Passport / Driving Licence Number',
          'Passport / Driving Licence Expiry Date',
          'Passport / Driving Licence Issuing Country',
          'Passport / Driving Licence  Filename',
          'VISA Issue Date',
          'VISA Expiry Date',
          'Indefinite Leave to Remain',
          'VISA Scan Filename']
          
        prospects.each do |p|
          # rows << [p.first_name,  p.last_name, 'work@flairevents.co.uk', 'Bar Staff', {nil: '', 'M' => 'Male', 'F' => 'Female'}[p.gender], 'Shack Events', p.etihad_id_number,  p.date_of_birth.try(:strftime, '%d/%m/%Y'), 'ALL CONTACTS - Manchester City', 'Manchester City External', 'Level 4', 'Level 4', etihad_pdf_name[ p.id],  p.nationality.try(:name),  p.id_number,  p.id_expiry.try(:strftime, '%d/%m/%Y'), '',  p.visa_issue_date.try(:strftime, '%d/%m/%Y'),  p.visa_expiry.try(:strftime, '%d/%m/%Y'),  (p.visa_expiry && p.visa_indefinite) ? 'YES' : '', etihad_photo_name[p.id], 'YES']
          val = if p.photo && File.extname(p.photo)
                  File.extname(p.photo)
                else
                  ''
                end
          visa_string = ''
          visa_expire = ''
          
          if p.nationality.try(:name) != 'United Kingdom'
            visa_string = p.etihad_id_number.to_s+"_VISA" 
            visa_exipre = p.visa_expiry.try(:strftime, '%d/%m/%Y') 
          end
          visa_indef = ''
          visa_indef = 'YES' if p.visa_indefinite.present?
          
          rows << [p.last_name,
            p.first_name,
            p.date_of_birth.try(:strftime, '%d/%m/%Y'),
            p.email,
            '+44',
            p.mobile_no,
            'Catering',
            'level 4',
            'Shack', # event&.name.split(" ")[0]
            p.etihad_id_number.to_s+"_ID",
            "#{p.etihad_id_number.to_s}_PHOTO#{val.to_s}",
            'Yes',
            p.nationality.try(:name),
            p.id_number,
            p.id_expiry.try(:strftime, '%d/%m/%Y'),
            '',
            p.etihad_id_number.to_s+"_PASSPORT",
            '',
            visa_exipre,
            visa_indef,
            visa_string]
        end

        widths = []
        rows.each do |row|
          row.each_with_index do |value, i|
            widths[i] = [widths[i]||0, value.to_s.length].max
          end
        end

        widths.each_with_index do |width, c|
          worksheet.set_column(c,c,width)
        end

        r = 0
        rows.each do |row|
          worksheet.write_row(r,0,row)
          r += 1
        end
        paths << {path: import_xlsx_path, name: 'Import Template.xlsx'}
        workbook.close
      end

      if create_allocation_spreadsheet
        allocation_xlsx_path = File.join(dir, 'Allocation.xlsx')
        workbook = WriteXLSX.new(allocation_xlsx_path)
        assignments = Assignment.where(event_id: event_id)
        dates = {}
        assignments.each {|a| dates[a.shift.date] = true}
        dates.keys.sort.each do |date|
          worksheet = workbook.add_worksheet(date.strftime('%d-%m-%Y'))
          shift_ids = Shift.where(date: date, event_id: event_id).pluck(:id).uniq
          assignment_ids = Assignment.where(shift_id: shift_ids)
          gigs = GigAssignment.where(assignment_id: assignment_ids).pluck(:gig_id).uniq.map { |id| Gig.find(id)}
          rows = []
          gigs.map {|g| g.prospect}.each do |p|
            rows << [p.etihad_id_number, p.last_name, p.first_name, "3rd Party Bars"]
          end
          widths = []
          rows.each do |row|
            row.each_with_index do |value, i|
              widths[i] = [widths[i]||0, value.to_s.length+1].max
            end
          end

          widths.each_with_index do |width, c|
            worksheet.set_column(c,c,width)
          end

          r = 0
          rows.each do |row|
            worksheet.write_row(r,0,row)
            r += 1
          end
        end
        paths << {path: allocation_xlsx_path, name: 'Allocation template.xlsx'}
        workbook.close
      end

      ##### Make summary
      summary_path = File.join(dir, 'summary.txt')
      File.open(summary_path, 'w') do |f|
        f.write("Etihad Download Summary for ")
        f.write("#{Event.find(event_id).name}\n")

        # excluded_event_ids = subtract_event_ids[event_id]
        excluded_event_ids = subtract_event_ids[event_id].nil? ? [] : subtract_event_ids[event_id]

        if excluded_event_ids.length > 0
          f.write("\nExcluded Info for Employees with gigs on these previous Etihad events:\n")
          excluded_event_ids.each do |id|
            f.write("- #{Event.find(id).name}\n")
          end
        end

        if create_photos
          if missing_photos.length > 0
            f.write("\nMissing Photos:\n")
            missing_photos.map {|id| Prospect.find(id)}.each do |p|
              f.write("- #{p.first_name} #{p.last_name} (#{p.id})\n")
            end
          else
            f.write("\nNo Missing Photos!\n")
          end
        end
        if create_ids
          if missing_ids.length > 0
            f.write("\nMissing IDs:\n")
            missing_ids.map {|id| Prospect.find(id)}.each do |p|
              f.write("- #{p.first_name} #{p.last_name} (#{p.id})\n")
            end
          else
            f.write("\nNo Missing IDs!\n")
          end
          f.write("\nEND\n")
        end
      end
      paths << {path: summary_path, name: 'summary.txt'}
      ##### send it!
      temp_zip_path = File.join(dir, 'etihad.zip')
      Zip::File.open(temp_zip_path, Zip::File::CREATE) do |zf|
        paths.each do |path|
          zf.add(path[:name], path[:path])
        end
      end
      FileUtils.cp(temp_zip_path, zip_path)
    end
    send_file(zip_path, disposition: 'attachment', filename: zip_filename)
  end

  def download_webapp_data
    event = Event.includes(gigs: [{gig_tax_weeks: [:tax_week]}, :job, :prospect, gig_assignments: {assignment: [:shift, :location, :job]}]).find(params[:event_id].to_i)

    event.gigs.update_all published: true, updated_at: DateTime.now

    published_gig_ids = []
    csv_string = CSV.generate do | csv |
      csv << ["Employee No", "Surname", "First Name", "Date", "Shift ID", "Shift Start",
              "Shift End", "Job Title", "Area", "Total of Pay", "Base Rate", "Holiday Pay",
              "Event ID", "Event Title", "Email", "Telephone", "Notes"]
      event.gigs.each do | gig |
        confirmed_dates = gig.gig_tax_weeks.map {|gig_tax_week| gig_tax_week.confirmed ? (gig_tax_week.tax_week.date_start..gig_tax_week.tax_week.date_end).to_a : []}.flatten.uniq

        confirmed_dates = confirmed_dates.reject {|date| date < DateTime.current.to_date}

        job             = gig.job
        prospect        = gig.prospect
        gig.gig_assignments.each do | gig_assignment |
          next unless gig_assignment.shift.date.in? confirmed_dates
          shift         = gig_assignment.shift
          location_name = gig_assignment.location.present? ? gig_assignment.location.name : nil
          job_name      = gig_assignment.job.present? ? (gig_assignment.job.public_name.present? ? gig_assignment.job.public_name : gig_assignment.job.name) : nil
          csv << [prospect.id, prospect.last_name, prospect.first_name, shift.date.strftime('%F'), gig_assignment.id, shift.time_start.strftime('%T'),
            shift.time_end.strftime('%T'), job_name, location_name,
            gig_assignment.job.rate_for_person(prospect, shift.date), gig_assignment.job.base_pay_for_person(prospect, shift.date), gig_assignment.job.holiday_pay_for_person(prospect, shift.date),
            event.id, event.display_name, prospect.email, prospect.mobile_no, nil]
          # We are removing the notes reference for now: gig.notes
        end
      end
    end

    send_data csv_string, type: 'text/csv', disposition: 'attachment', filename: ActiveStorage::Filename.new("WebAppData-#{event.id}-#{event.name}.csv").sanitized
  end

  def download_scanned_bar_ids_data
    @prospect = Prospect.find(params[:id])
    a4_width = 595.28 - 2*36
    a4_height = 841.89 - 2*36
    photo_size = [a4_width, a4_height/2]
    #top-left-corners
    photo_location = {
      0 => [0,a4_height],
      1 => [0,a4_height/2]
    }
    pdf = Prawn::Document.new(page_size: 'A4')
    pdf.font_size = 9
    pdf.font_families.update("OpenSans" => {
      :normal => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold_italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf")
    })
    pdf.font "OpenSans"
    pdf.text("Flair Events", size: 16, style: :bold)
    pdf.move_down(8)

    file_exts = @prospect.scanned_ids.pluck(:photo).map { |path| path.split('.').last }
    # pdf.start_new_page() unless file_exts.all?('pdf')
    pdf_files = []

    @prospect.scanned_bar_licenses.each_with_index do |scanned_id, i|
      if scanned_id.photo.split('.').last == 'pdf'
        pdf_path = File.join(Flair::Application.config.shared_dir, 'scanned_bar_licenses', scanned_id.photo)
        if File.exists?(pdf_path)
          pdf_files << pdf_path
        end
      else
        image_path = File.join(Flair::Application.config.shared_dir, 'scanned_bar_licenses_large', scanned_id.photo)
        if File.exists?(image_path)
          orig_size = FastImage.size(image_path)
            pdf.image image_path, {fit: photo_size}
        end
      end
      pdf.move_down(5)
    end

    pdf_files.each do |path|
      PDF::Reader.new(path).page_count.times.each do |index|
        pdf.start_new_page(template: path, template_page: index + 1)
      end
    end

    temp_path = Tempfile.new("scanned_id_#{@prospect.id}.pdf", binmode: true)
    temp_path.write(pdf.render)
    send_file(temp_path, disposition: 'attachment', filename: "#{@prospect.name}-#{@prospect.id}.pdf")
  end

  def download_scanned_ids_data
    @prospect = Prospect.find(params[:id])
    a4_width = 595.28 - 2*36
    a4_height = 841.89 - 2*36
    photo_size_4 = [a4_width/2, a4_height/2 ]
    photo_size_2 = [a4_width, a4_height/2]
    #top-left-corners
    photo_locations_2 = {
      0 => [0,a4_height],
      1 => [0,a4_height/2]
    }
    photo_locations_4 = {
      0 => [0,a4_height],
      1 => [a4_width/2,a4_height],
      2 => [0,a4_height/2],
      3 => [a4_width/2, a4_height/2]
    }

    pdf = Prawn::Document.new(page_size: 'A4')
    pdf.font_size = 9
    pdf.font_families.update("OpenSans" => {
      :normal => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold_italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf")
    })
    pdf.font "OpenSans"

    # draw letterhead
    pdf.text("Flair Events", size: 16, style: :bold)
    pdf.move_down(8)
      
    photo_path = File.join(Flair::Application.config.shared_dir, "/prospect_photos/#{@prospect.photo}")
    if File.exists?(photo_path)
      pdf.image photo_path, { fit: [a4_width/3, a4_height/3] }
      pdf.move_down(8)
    end

    pdf.text "Name: ", size: 13, style: :bold
    pdf.text @prospect.name.presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Nationality: ", size: 13, style: :bold
    pdf.text @prospect.nationality.name.presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Id Number: ", size: 13, style: :bold
    pdf.text @prospect.id_number.presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Id Expiry: ", size: 13, style: :bold
    pdf.text @prospect.id_expiry.try(:to_print).presence || 'N/A'
    pdf.move_down(8)
    pdf.text "NI Number: ", size: 13, style: :bold
    pdf.text @prospect.ni_number.presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Date of Birth: ", size: 13, style: :bold
    pdf.text @prospect.date_of_birth.try(:to_print).presence || 'N/A'
    pdf.move_down(8)
    pdf.text "ID Approve Date: ", size: 13, style: :bold
    pdf.text @prospect.id_sighted.try(:to_print).presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Share Code: ", size: 13, style: :bold
    pdf.text @prospect.share_code.presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Visa Expiry: ", size: 13, style: :bold
    pdf.text @prospect.visa_expiry.try(:to_print).presence || 'N/A'
    pdf.move_down(8)
    pdf.text "Visa Indefinite? ", size: 13, style: :bold
    pdf.text(@prospect.visa_indefinite? ? 'Yes' : 'No').presence || 'N/A'

    if @prospect.scanned_ids.length > 2
      photo_location = photo_locations_4
      photo_size = photo_size_4
    else
      photo_location = photo_locations_2
      photo_size = photo_size_2
    end

    file_exts = @prospect.scanned_ids.pluck(:photo).map { |path| path.split('.').last }
    pdf.start_new_page() unless file_exts.all?('pdf')
    pdf_files = []

    @prospect.scanned_ids.each_with_index do |scanned_id, i|
      if scanned_id.photo.split('.').last == 'pdf'
        pdf_path = File.join(Flair::Application.config.shared_dir, 'scanned_ids', scanned_id.photo)
        if File.exists?(pdf_path)
          pdf_files << pdf_path
        end
      else
        image_path = File.join(Flair::Application.config.shared_dir, 'scanned_ids_large', scanned_id.photo)
        if File.exists?(image_path)
          orig_size = FastImage.size(image_path)
          if orig_size[0] < orig_size[1] && photo_size[0] > photo_size[1] || orig_size[0] > orig_size[1] && photo_size[0] < photo_size[1]
            pdf.rotate 90, origin: photo_location[i]  do
              pdf.image image_path, {fit: [photo_size[1], photo_size[0]], at: [photo_location[i][0]-photo_size[1], photo_location[i][1]]}
            end
          else
            pdf.image image_path, {fit: photo_size, at: photo_location[i]}
          end
        end
      end
    end

    if @prospect.share_code_files.count > 0
      path = File.join(Flair::Application.config.shared_dir, 'prospect_share_codes', @prospect.share_code_files.last.path) 
      if File.exists?(path)
        pdf_files << path
      end
    end

    pdf_files.each do |path|
      PDF::Reader.new(path).page_count.times.each do |index|
        pdf.start_new_page(template: path, template_page: index + 1)
      end
    end

    temp_path = Tempfile.new("scanned_id_#{@prospect.id}.pdf", binmode: true)
    temp_path.write(pdf.render)
    send_file(temp_path, disposition: 'attachment', filename: "#{@prospect.name} - #{@prospect.id}.pdf")
  end

  def download_dbs_data
    event = Event.find(params[:event_id])
    display_name = event.display_name || ""

    filename = display_name + " DBS Reports.xlsx"

    io = StringIO.new
    wb = WriteXLSX.new(io)
    format = Report.format_workbook(wb)

    ws = wb.add_worksheet("DBS Report")
    Report.setup_worksheet(ws)

    [10,10,25,10,5,10,10,5,5,10,5,10,20,15].each_with_index { |width,i| ws.set_column(i,i,width) }

    ws.repeat_rows(0,1)
    rt = RowTracker.new(ws, 18+RowTracker.default_height)
    rt.next_row(18)

    ws.write_row(rt.row, 0, ['Surname', 'First name', 'Email', 'Mobile', 'DBS', 'DBS Type','Certificate No.', 'Issue Date', 'Clean?', 'C-19 Pass', 'Prospect ID#', 'Live Y/N', '1st Shift Date', 'Selected Event', 'Selected Event ID'], format[:bold_center])
    rt.next_row

    gigs = event.gigs.joins(:prospect).order('prospects.last_name')

    gigs.includes(:prospect).each do |gig|
      prospect = gig.prospect

      clean = prospect.is_clean == true ? 'Yes' : 'No'
      c_19 = prospect.has_c19_test == true ? 'Yes' : 'No'
      dbs = prospect.dbs_certificate_number != nil ? 'Yes' : 'No'
      live = gig.status == 'Active' ? 'Yes' : 'No'
      assignment_ids = gig.gig_assignments.joins(:assignment).pluck('assignments.shift_id')
      shift_dates = Shift.find(assignment_ids).pluck('date').sort

      first_shift_date = shift_dates[0] ? shift_dates[0].strftime("%d/%m/%y") : ""
      issue_date = prospect.dbs_issue_date ? prospect.dbs_issue_date.strftime("%d/%m/%y") : ""

      ws.write_row(rt.row, 0, [prospect.last_name, prospect.first_name, prospect.email, prospect.mobile_no, dbs, prospect.dbs_qualification_type, prospect.dbs_certificate_number, issue_date, clean, c_19, prospect.id, live, first_shift_date, event.display_name, event.id], format[:border1_center])
      rt.next_row
    end


    wb.close
    headers['Content-Type'] = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""
    puts params[:event_id]
    render plain: io.string
  end

  #*************
  # LOGIN/LOGOUT
  #*************

  def login
    unless current_user.is_a?(Officer)
      logout_account
    end

    if request.post? # form submission
      email, password = params[:login_email], params[:login_password]
      if email.blank? || password.blank?
        flash.now[:title] = "Sorry!"
        flash.now[:error] = "You need to enter both e-mail address and password."
        @login_email = email
      else
        if login_as_officer(email, password) == :success
          redirect_to '/office'
        else
          flash.now[:title] = "Sorry!"
          flash.now[:error] = "Please try entering your e-mail address and password again."
          @login_email = email
        end
      end
    end
  end

  def relogin
    (logout and return) unless request.post?
    if current_user && !current_user.is_a?(Officer)
      logout_account
    end
    email, password = params[:login_email], params[:login_password]
    if login_as_officer(email, password) == :success
      render json: {}, status: :ok
    else
      render json: {}, status: :unauthorized
    end
  end

  def logout
    logout_account
    redirect_to '/office/login'
  end

  def fetch_session_log
    @session_logs = []
    SessionLog.where(account: Officer.find(params[:id]).account).order('login_time DESC').each do |sl|
      href = ((coords = sl.login_ip_coordinates.try(:split, ',')) ? href = "https://maps.google.com/maps?q=#{coords[0]},#{coords[1]}" : nil)
      @session_logs << {
        login_ip:              sl.login_ip,
        login_ip_href:         href,
        login_ip_location:     sl.login_ip_location,
        login_time:            sl.login_time,
        logout_time:           sl.logout_time,
      }
    end

    render layout: false
  end

private

  def get_todos(last_time)
    # Each "To-Do" item needs a unique ID
    # This is slightly problematic, since different types of to-do items may be derived from different DB tables
    #   and directly using DB primary keys could easily lead to a collision
    # As a stop-gap measure, I am hashing the DB primary keys with a different "magic number" for each table
    # When the to-do item is processed, the client will send back the ID which is stored INSIDE the record...
    #   which is the actual DB primary key
    todos = {}
    change_requests = last_time ? ChangeRequest.where('updated_at > ?', last_time) : ChangeRequest.all
    change_requests.each do |cr|
      todos[todo_id_for_cr(cr)] = {
        id: cr.id,
        magicid: todo_id_for_cr(cr),
        prospect_id: cr.prospect_id,
        type: 'change',
        data: {content: cr.content},
        choices: [{label: 'Accept', url: '/office/accept_change_request/'}, {label: 'Reject', url: '/office/reject_change_request/'}]
      }
    end

    # The following will do an INNER JOIN, ensuring that only prospects with at least 1 ID scan uploaded will be found
    # The WHERE condition will select prospects whose ID has not been approved yet
    uk_roi_ids = Country.uk_roi.pluck(:id)
    Prospect.joins(:scanned_ids)
      .where('(id_sighted IS NULL AND nationality_id IN (?)) OR
              (id_sighted IS NULL AND share_code IS NOT NULL AND nationality_id NOT IN (?))', uk_roi_ids, uk_roi_ids).each do |prospect|
      scanned_ids = last_time ? prospect.scanned_ids.where('updated_at > ?', last_time) : prospect.scanned_ids
      if scanned_ids.length > 0
        todos[todo_id_for_id_approval(prospect)] = {
          id: prospect.id,
          magicid: todo_id_for_id_approval(prospect),
          type: prospect.nationality.others? ? 'share_code' : 'id_approval',
          data: {name: prospect.name, prospect_id: prospect.id, id_number: prospect.id_number, id_expiry: prospect.id_expiry.try(:to_print), id_type: prospect.id_type,
                 ni_number: prospect.ni_number, date_of_birth: prospect.date_of_birth.try(:to_print), nationality: prospect.nationality_id,
                 visa_issue_date: prospect.visa_issue_date.try(:to_print), visa_indefinite: prospect.visa_indefinite, share_code: prospect.share_code,
                 visa_number: prospect.visa_number, visa_expiry: prospect.visa_expiry.try(:to_print), has_share_code_file: prospect.share_code_files.count > 0,
                 condition: prospect.condition, scanned_ids: scanned_ids.map { |scanned| { id: scanned.id, extension: File.extname(scanned.photo) } }},
          choices: [{label: 'Accept', url: '/office/approve_ids/'}, {label: 'Reject', needs_reason: true, url: '/office/reject_ids/'}]
        }
      end
    end

    todos
  end

  def todo_id_for_cr(change_request)
    # make sure this number will fit in a PostgreSQL integer column (4 bytes)
    # (we store these IDs in the 'deletions' table)
    (9820289 * change_request.id) % 2_000_000_000
  end

  def todo_id_for_id_approval(prospect)
    (2598641 * prospect.id) % 2_000_000_000
  end

  def render_if_nonexistent(arclass, id, message)
    unless arclass.exists? id
      params = {status: 'ok', deleted: {}, sync: true} #We tell the office zone to remove this object, and to do a sync in case there are others
      params[:message] = message if message
      params[:deleted][arclass.table_name] = [id]
      render json: params
    end
  end

  def putstar(message)
    5.times { puts("**************************") }
    puts(message)
    5.times { puts("**************************") }
  end

  def send_to_object(object, prop, value)
    object.send(:"#{prop}=", value)
  end

  ########################################################################################
  ##### Mass Assignment Param Checking (Must call this before mass-assigning params) #####
  ########################################################################################

  def assignment_email_template_params(params)
    params.permit(
      :additional_info,
      :arrival_time,
      :confirmation,
      :contact_number,
      :details,
      :event_id,
      :meeting_location,
      :meeting_location_coords,
      :name,
      :office_message,
      :on_site_contact,
      :transport,
      :uniform,
      :welfare
    )
  end

  def booking_params(params)
    params.permit(
      :any_other_information,
      :breaks,
      :crew_required,
      :dates,
      :date_received,
      :date_sent,
      :event_description,
      :food,
      :health_safety,
      :invoicing,
      :job_description,
      :meeting_location,
      :minimum_hours,
      :office_notes,
      :rates,
      :selling_points,
      :staff_qualities,
      :terms,
      :timesheets,
      :timings,
      :transport,
      :uniform,
      :wages,
    )
  end

  def bulk_interview_params(params)
    params.permit(
      :address,
      :city,
      :date_end,
      :date_start,
      :directions,
      :interview_type,
      :name,
      :note_for_applicant,
      :photo,
      :positions,
      :post_code,
      :target_region_id,
      :status,
      :venue,
    )
  end

  def client_params(params)
    params.permit(
      :accountant_email,
      :active,
      :address,
      :company_type,
      :email,
      :flair_contact,
      :invoice_notes,
      :name,
      :notes,
      :phone_no,
      :primary_client_contact_id,
      :safety_client_contact_id,
      :safety_date_received,
      :safety_date_sent,
      :terms_client_contact_id,
      :terms_date_received,
      :terms_date_sent,
    )

  end

  def client_contact_params(params)
    params.permit(
      :email,
      :first_name,
      :last_name,
      :mobile_no,
    )
  end

  def event_params(params)
    params.permit(
      :accom_address,
      :remove_task,
      :accom_booked_by,
      :accom_booking_dates,
      :accom_booking_ref,
      :accom_cancellation_policy,
      :accom_distance,
      :accom_hotel_name,
      :accom_notes,
      :accom_parking,
      :accom_payment_method,
      :accom_phone,
      :accom_room_info,
      :accom_status,
      :accom_total_cost,
      :accom_wifi,
      :additional_staff,
      :address,
      :admin_completed,
      :blurb_closing,
      :blurb_job,
      :blurb_legacy,
      :blurb_opening,
      :blurb_shift,
      :blurb_sign_up_message,
      :blurb_subtitle,
      :blurb_title,
      :blurb_transport,
      :blurb_uniform,
      :blurb_wage_additional,
      :category_id,
      :date_callback_due,
      :date_end,
      :date_start,
      :default_assignment_id,
      :default_job_id,
      :default_location_id,
      :display_name,
      :expense_notes,
      :post_notes,
      :fullness,
      :jobs_description,
      :leader_accomodation,
      :leader_arrival_time,
      :leader_client_contact_id,
      :leader_energy,
      :leader_flair_phone_no,
      :leader_food,
      :leader_general,
      :leader_handbooks,
      :leader_job_role,
      :leader_meeting_location,
      :leader_meeting_location_coords,
      :leader_staff_arrival,
      :leader_staff_job_roles,
      :leader_transport,
      :leader_uniform,
      :location,
      :name,
      :notes,
      :task,
      :office_manager_id,
      :senior_manager_id,
      :other_info,
      :paid_breaks,
      :post_code,
      :public_date_end,
      :public_date_start,
      :require_training_bar_hospitality,
      :require_training_customer_service,
      :require_training_ethics,
      :require_training_sports,
      :requires_booking,
      :send_scheduled_to_work_auto_email,
      :show_in_featured,
      :show_in_history,
      :show_in_home,
      :show_in_ongoing,
      :show_in_payroll,
      :show_in_planner,
      :show_in_public,
      :show_in_time_clocking_app,
      :site_manager,
      :size_id,
      :staff_needed,
      :status,
      :website,
      :reviewed_by_manager,
      :accom_booking_via,
      :accom_refund_date,
      :is_restricted,
      :shift_start_time,
      :has_bar,
      :has_sport,
      :has_hospitality,
      :has_festivals,
      :has_office,
      :has_retail,
      :has_warehouse,
      :has_promotional,
      :request_message,
      :spares_message,
      :applicants_message,
      :action_message,
      :senior_manager_id
    )
  end

  def event_task_params(params)
    params.permit(
      :completed,
      :due_date,
      :event_id,
      :notes,
      :additional_notes,
      :manager_notes,
      :confirmed,
      :officer_id,
      :second_officer_id,
      :template_id,
      :task_completed
    )
  end

  def expense_params(params)
    params.permit(
      :cost,
      :name,
      :notes
    )
  end

  def faq_entry_params(params)
    params.permit(
      :answer,
      :position,
      :question,
      :topic,
    )
  end

  def gig_params(params)
    params.permit(
      :event,
      :event_id,
      :job_id,
      :location_id,
      :miscellaneous_boolean,
      :notes,
      :prospect,
      :prospect_id,
      :rating,
      :status,
    )
  end

  def gig_request_params(params)
    params.permit(
      :event,
      :spare,
      :prospect,
      :is_best,
      :left_voice_message,
      :email_status,
      :texted,
      :notes,
      :job_id,
    )
  end

  def interview_block_params(params)
    params.permit(
      :bulk_interview_id,
      :date,
      :number_of_applicants_per_slot,
      :slot_mins,
      :time_end,
      :time_start,
      :is_morning,
      :morning_applicants,
      :is_afternoon,
      :afternoon_applicants,
      :is_evening,
      :evening_applicants
    )
  end

  def invoice_params(params)
    params.permit(
      :date_emailed,
      :event_client_id,
      :notes,
      :status,
      :tax_week_id,
      :who,
    )
  end

  def job_params(params)
    params.permit(
      :description,
      :event_id,
      :include_in_description,
      :name,
      :pay_17_and_under,
      :pay_18_and_over,
      :pay_21_and_over,
      :pay_25_and_over,
      :public_name,
      :shift_information,
      :number_of_positions,
      :uniform_information,
      :other_information,
      :new_description,
    )
  end

  def library_item_params(params)
    params.permit(
      :filename,
      :name,
    )
  end

  def location_params(params)
    params.permit(
      :name,
      :type
    )
  end

  def assignment_params(params)
    params.permit(
      :event_id,
      :job_id,
      :location_id,
      :shift_id,
      :staff_needed
    )
  end

  def officer_params(params)
    params.permit(
      :email,
      :first_name,
      :last_name,
      :role,
      :active_operational_manager,
      :senior_manager
    )
  end

  def pay_week_params(params)
    params.permit(
      :allowance,
      :deduction,
      :friday,
      :job_id,
      :monday,
      :rate,
      :saturday,
      :status,
      :sunday,
      :thursday,
      :tuesday,
      :wednesday,
    )
  end

  def prospect_params(params)
    params.permit(
      :address,
      :city_of_study,
      :address2,
      :bank_account_name,
      :bank_account_no,
      :bank_sort_code,
      :bar_experience,
      :bar_license_expiry,
      :bar_license_issued_by,
      :bar_license_no,
      :bar_license_type,
      :city,
      :client_id,
      :country,
      :date_end,
      :date_inactive,
      :date_of_birth,
      :dbs_certificate_number,
      :email,
      :emergency_name,
      :emergency_no,
      :first_name,
      :gender,
      :good_bar,
      :good_hospitality,
      :good_management,
      :good_promo,
      :good_sport,
      :home_no,
      :id_expiry,
      :id_number,
      :id_sighted,
      :id_type,
      :interview,
      :last_name,
      :manager_level,
      :mobile_no,
      :nationality,
      :nationality_id,
      :ni_number,
      :notes,
      :performance_notes,
      :post_code,
      :preferred_facetime,
      :preferred_phone,
      :preferred_skype,
      :prefers_afternoon,
      :prefers_early_evening,
      :prefers_facetime,
      :prefers_in_person,
      :prefers_midweek,
      :prefers_morning,
      :prefers_phone,
      :prefers_skype,
      :prefers_weekend,
      :qualification_dbs,
      :qualification_food_health_2,
      :rating,
      :send_marketing_email,
      :status,
      :status,
      :student_loan,
      :tax_choice,
      :training_type,
      :visa_expiry,
      :visa_indefinite,
      :visa_issue_date,
      :visa_number,
      :left_voice_message,
      :headquarter,
      :texted_date,
      :email_status,
      :missed_interview_date,
      :flair_image,
      :experienced,
      :chatty,
      :confident,
      :language,
      :big_teams,
      :all_teams,
      :bespoke,
      :prospect_character,
      :team_notes,
      :completed_contracts,
      :cancelled_contracts,
      :cancelled_eighteen_hrs_contracts,
      :no_show_contracts,
      :non_confirmed_contracts,
      :held_spare_contracts,
      :has_bar_and_hospitality,
      :has_sport_and_outdoor,
      :has_promotional_and_street_marketing,
      :has_merchandise_and_retail,
      :has_reception_and_office_admin,
      :has_festivals_and_concerts,
      :has_bar_management_experience,
      :has_staff_leadership_experience,
      :has_festival_event_bar_management_experience,
      :has_event_production_experience,
      :dbs_issue_date,
      :hospitality_skill,
      :warehouse_skill,
      :has_hospitality_marketing,
      :has_warehouse_marketing,
      :has_c19_test,
      :test_site_code,
      :is_clean,
      :is_convicted,
      :c19_tt_at,
      :share_code,
      :dbs_qualification_type,
      :condition,
    )
  end

  def shift_params(params)
    params.permit(
      :date,
      :event_id,
      :name,
      :time_end,
      :time_start,
    )
  end

  def team_leader_role_params(params)
     params.permit(
       :event_id,
       :user_id,
       :user_type,
       :enabled
     )
  end

  def text_block_params(params)
    params.permit(
      :contents,
      :date_published,
      :key,
      :status,
      :title,
      :type,
    )
  end

  def tag_params(params)
    params.permit(:name)
  end

  def timesheet_params(params)
    params.permit(
      :break_minutes,
      :invoiced,
      :notes,
      :rating,
      :status,
      :time_end,
      :time_start,
    )
  end

  def questionnaire_params(params)
    params.permit(
      :contact_via_text,
      :contact_via_whatsapp,
      :bar_management_experience,
      :staff_leadership_experience,
      :festival_event_bar_management_experience,
      :event_production_experience,
      :week_days_work,
      :weekends_work,
      :day_shifts_work,
      :evening_shifts_work,
      :has_bar_and_hospitality,
      :has_sport_and_outdoor,
      :has_promotional_and_street_marketing,
      :has_merchandise_and_retail,
      :has_reception_and_office_admin,
      :has_festivals_and_concerts,
      :dbs_qualification,
      :food_health_level_two_qualification,
      :has_bar,
      :has_logistics,
      :city_of_study
    )
  end
end
