module Api
  module V1
    MIN_APP_VERSION = '1.0.3'

    class TimeClockingController < ApiController
      def login
        email = params[:email]

        # The same email may be used for multiple accounts. We'll give priority as follows: 1) Officer, 2) Client, 3) Employee
        # This could happen if there are test accounts using the same email
        [Officer, ClientContact, Prospect].each do |modelType|
          if ((user = modelType.find_by_email(email)) &&
              TeamLeaderRole.where(user_id: user.account.user_id, user_type: user.account.user_type).any? &&
              user.allowTimeClockingAppLogin?)
            api_login(user, params[:password]) and return
          end
        end
        render json: {status: 'error', message: 'Only Team Leaders Can Login'}, status: :unauthorized
      end

      COLUMNS = {
          assignments: [:id, :event_id, :job_id, :shift_id, :location_id, :staff_needed, :staff_count, :date],
          client_contacts: [:id, :first_name, :last_name, :mobile_no, :company_name],
          events: [:id, :display_name, :photo, :status, :location, :address, :post_code, :leader_general,
                   :leader_meeting_location, :leader_accomodation, :leader_job_role, :leader_arrival_time,
                   :leader_handbooks, :leader_staff_job_roles, :leader_energy, :leader_uniform, :leader_food,
                   :leader_transport, :leader_staff_arrival, :leader_client_contact_id, :leader_flair_phone_no,
                   :blurb_title, :blurb_subtitle,
                   :blurb_opening, :blurb_job, :blurb_shift, :blurb_wage_additional, :blurb_uniform, :blurb_transport,
                   :blurb_closing, :leader_meeting_location_coords],
          gigs: [:id, :prospect_id, :event_id],
          gig_assignments: [:id, :gig_id, :assignment_id, :assignment_id_updated_at, :date, :prospect_id, :event_id],
          jobs: [:id, :event_id, :prospect_id, :name],
          locations: [:id, :event_id, :name, :type],
          prospects: [:id, :photo, :last_name, :first_name, :mobile_no, :ethics_meaning, :customer_service_meaning, :average_rating, :gigs_count],
          shifts: [:id, :datetime_start, :datetime_end, :event_id, :date]
      }

      ###### We are only going to send the rows required for the team leader, and the columns required for the app
      def data
        begin
          last_time = params[:last_time] || Date.new(1900,1,1)
          prospect_photo_dir = File.join(Flair::Application.config.shared_dir, 'prospect_photos')
          event_photo_dir    = File.join(Flair::Application.config.shared_dir, 'public', 'event_photos')
          account = @current_user.account

          ###### These objects are used in selecting child objects.
          ###### Thus, we always want to get ALL ID's for cases where the parent object may not have changed,
          ###### but the child object did change
          event_ids = TeamLeaderRole.where(user_id: account.user_id, user_type: account.user_type, enabled: true).pluck(:event_id)
          client_contact_ids = Event.where(id: event_ids).pluck(:leader_client_contact_id).uniq
          gig_ids = Gig.where(event_id: event_ids).pluck(:id)
          prospect_ids =  Gig.where(id: gig_ids).pluck(:prospect_id).uniq

          ##### Now get the relevant records, only retrieving what has been updated since last time
          assignments =     latest_json(Assignment.includes(:shift).where(event_id: event_ids), last_time, COLUMNS[:assignments])
          client_contacts = latest_json(ClientContact.where(id: client_contact_ids), last_time, COLUMNS[:client_contacts])
          events =          latest_json(Event.where(id: event_ids), last_time, COLUMNS[:events])
          gigs =            latest_json(Gig.where(event_id: event_ids), last_time, COLUMNS[:gigs])
          gig_assignments = latest_json(GigAssignment.includes(:assignment, gig: [:prospect, :event]).where(gig_id: gig_ids), last_time, COLUMNS[:gig_assignments])
          jobs =            latest_json(Job.where(event_id: event_ids), last_time, COLUMNS[:jobs])
          locations =       latest_json(Location.where(event_id: event_ids), last_time, COLUMNS[:locations])
          prospects =       latest_json(Prospect.includes(:questionnaire).where(id: prospect_ids), last_time, COLUMNS[:prospects])
          shifts =          latest_json(Shift.where(event_id: event_ids), last_time, COLUMNS[:shifts])

          render json: {
            status: 'ok',
            api_info: {
              min_app_version: MIN_APP_VERSION
            },
            database: {
              assignments:     assignments,
              client_contacts: client_contacts,
              events:          events,
              gigs:            gigs,
              gig_assignments: gig_assignments,
              jobs:            jobs,
              locations:       locations,
              prospects:       prospects,
              shifts:          shifts,
            },
            files: {
              prospects: encode_files_from_objects(Prospect.where(id: prospect_ids), prospect_photo_dir, :photo, last_time),
              events:    encode_files_from_objects(Event.where(id: event_ids),       event_photo_dir,    :photo, last_time)
            }
          }, status: :ok
        rescue => e
          ExceptionNotifier.notify_exception(e)
          puts("ERROR: #{e}")
          puts(e.backtrace)
          render json: {status: 'error', message: 'There was an error downloading data. Please report to Flair Event Staffing.'}, status: :internal_server_error
        end
      end

      def upload_report
        begin
          data = params #In case we massage the data

          signature_dir = File.join(Flair::Application.config.shared_dir, 'time_clock_report_signatures')
          time_clock_report = TimeClockReport.where(event_id: data[:event_id],
                                                    date: Date.parse(data[:date]),
                                                    user_id: params[:user_id],
                                                    user_type: params[:user_type]).first_or_initialize

          if time_clock_report.status == 'ACCEPTED'
            render json: {status: 'already_accepted'}
          else
            ##### Update/Add Gig Assignments to match what was actually worked
            ##### Create UnworkedGigAssignments if a gig_assignment was not worked
            data[:gig_assignments].each do |gig_assignment|
              if %w[Moved Finished].include?(gig_assignment[:status])
                if (local_gig_assignment = GigAssignment.where(id: gig_assignment[:id], gig_id: gig_assignment[:gig_id]).first)
                  local_gig_assignment.assignment_id = gig_assignment[:assignment_id]
                  local_gig_assignment.save
                else
                  GigAssignment.create(gig_id: gig_assignment[:gig_id], assignment_id: gig_assignment[:assignment_id])
                end
              elsif ["No Show", "Sent Home", "Cancelled"].include?(gig_assignment[:status])
                if (local_gig_assignment = GigAssignment.where(id: gig_assignment[:id],
                                                               gig_id: gig_assignment[:gig_id],
                                                               assignment_id: gig_assignment[:assignment_id]).first)
                  local_gig_assignment.destroy
                end
                unworked_gig_assignment = UnworkedGigAssignment.first_or_initialize( gig_id: gig_assignment[:gig_id],
                                                                                     assignment_id: gig_assignment[:assignment_id])
                unworked_gig_assignment.reason = gig_assignment[:status]
                unworked_gig_assignment.save
              else
                raise "What? Got an unexpected status: #{gig_assignment[:status]}"
              end
            end

            ##### Create timesheet entries with status
            data[:timesheets].select {|ts_info| ts_info[:status] == 'Finished'}.each do |ts_info|
              tse = TimesheetEntry.where(gig_assignment_id: ts_info[:gig_assignment_id], time_clock_report: time_clock_report).first_or_initialize
              tse.gig_assignment_id = ts_info[:gig_assignment_id]
              tse.time_start    = datetime_string_to_h_m_string(ts_info[:time_start])
              tse.time_end      = datetime_string_to_h_m_string(ts_info[:time_end])
              tse.tax_week_id   = TaxWeek.where('date_start <= ? AND ? <= date_end', ts_info[:date], ts_info[:date]).pluck(:id).first
              tse.break_minutes = ts_info[:break_minutes].to_i
              tse.rating        = ts_info[:rating] if ts_info[:rating] > 0
              tse.notes         = ts_info[:notes]
              tse.status        = 'TO_APPROVE'
              tse.save!
            end

            time_clock_report.notes = data[:event_dates][:notes]
            time_clock_report.client_notes = data[:event_dates][:client_notes]
            time_clock_report.client_rating = data[:event_dates][:flair_rating]
            time_clock_report.signed_by_name = "#{data[:client_info][:last_name]}, #{data[:client_info][:first_name]}"
            time_clock_report.signed_by_job_title = data[:client_info][:job_title]
            time_clock_report.signed_by_company_name = data[:client_info][:company_name]
            time_clock_report.status = 'SUBMITTED'
            time_clock_report.date_submitted = DateTime.now
            time_clock_report.save

            file_name = "#{time_clock_report.id}.png"
            signature_path = "#{signature_dir}/#{file_name}"
            decode_to_file(data[:event_dates][:signature], signature_path)
            system("pngquant --force --ext .png --speed 1 #{signature_path}")
            time_clock_report.signature = file_name

            time_clock_report.save

            render json: {status: 'ok'}, status: :ok
          end
        rescue => e
          ExceptionNotifier.notify_exception(e)
          puts("ERROR: #{e}")
          puts(e.backtrace)
          render json: {status: 'error', message: 'There was an error uploading the report. Please report to Flair Event Staffing.'}, status: :internal_server_error
        end
      end

      def latest_json(query, last_time, columns)
        query.where('updated_at > ?', last_time).as_json({only: columns})
      end

      def datetime_string_to_h_m_string(datetime_string)
        datetime = DateTime.parse(datetime_string)
        "#{datetime.hour.to_s.rjust(2,'0')}:#{datetime.min.to_s.rjust(2,'0')}"
      end
    end
  end
end
