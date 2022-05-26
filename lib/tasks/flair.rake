
namespace :assets do
  # It requires ACK - http://betterthangrep.com/
  task :find_unused_images do
    images = Dir.glob('app/assets/images/**/*')

    images_to_delete = []
    images.each do |image|
      unless File.directory?(image)
        # print "\nChecking #{image}..."
        print '.'
        result = `ack -1 --type-set=mytype=.rb,.css,.scss,.haml,.coffee,.js,.erb,.en,.th,.html,.slim,.less,.sass #{File.basename(image)}`
        if result.empty?
          images_to_delete << image
        else
        end
      end
    end
    puts "\n\nDelete unused files running the command below:"
    puts "#{images_to_delete.join(" \n")}\n\n"
    puts "-----------------------------------"
    puts "rm #{images_to_delete.join(" ")}"
  end
end

namespace :db do
  desc "Update DB stored procedures"
  task :add_procedures => [:environment] do
    path = File.expand_path('../../db/stored_procedures.sql', __dir__)
    `psql #{ActiveRecord::Base.connection.pool.spec.config[:database]} --file="#{path}"`
    puts "Done"
  end

  desc "Load test data (aside from legacy data which is also being used for testing)"
  task :load_test_data => [:environment] do
    load "#{Rails.root}/db/test_data.rb"
  end

  desc "Save backup copy of all data in DB"
  task :backup => [:environment] do
    backup_dir = File.join(Flair::Application.config.shared_dir, 'db_backups')
    `mkdir -p #{backup_dir}`

    backup_name = "backup-#{Date.today.strftime('%Y-%m-%d')}.sql.gz"
    db_name = ActiveRecord::Base.connection.pool.spec.config[:database]
    `env PGPASSWORD=priorityrummagecoup pg_dump #{db_name} | gzip >#{backup_dir}/#{backup_name}`

    backups = Dir["#{backup_dir}/*.sql.gz"]

    # we keep the backup from the 1st of each month indefinitely
    backups = backups.reject { |b| b[/\d\d\d\d-\d\d-(\d\d)/, 1] == '01' }

    # aside from the 1st of each month, keep up to 20 other backups
    # keep the newest ones, delete the older ones
    if backups.size > 30
      to_delete = backups.sort.reverse.drop(30)
      to_delete.each { |f| `rm #{f}` }
    end
  end

  desc "Backup letsyencrypt data"
  task :backup_letsencrypt => [:environment] do
    backup_dir = File.join(Flair::Application.config.shared_dir, 'letsencrypt_backups')
    `mkdir -p #{backup_dir}`

    backup_name = "backup-#{Date.today.strftime('%Y-%m-%d')}-letsencrypt.tar.gz"
    `tar -czvf #{backup_dir}/#{backup_name} /etc/letsencrypt`

    backups = Dir["#{backup_dir}/*.gz"]

    # we keep the backup from the 1st of each month indefinitely
    backups = backups.reject { |b| b[/\d\d\d\d-\d\d-(\d\d)/, 1] == '01' }

    # aside from the 1st of each month, keep up to 20 other backups
    # keep the newest ones, delete the older ones
    if backups.size > 30
      to_delete = backups.sort.reverse.drop(30)
      to_delete.each { |f| `rm #{f}` }
    end
  end


  desc "Updated Post Regions"
  task :update_post_regions => [:environment] do
    require 'csv'
    data_dir = File.join(__dir__,'../../db/legacy_data')

    def makeRowSafe(row)
      row = row.to_hash
      row.default_proc = proc do |_,key|
        raise "Key #{ key } is not valid"
      end
      row
    end
    regions = {}

    CSV.parse(File.read(data_dir+'/Regions.tsv'), :headers => true, :col_sep => "\t").each_with_index do |row,i|
      row = makeRowSafe(row)
      regions[row['RegionCode']] = Region.find_by_name(row['Region'])
    end

    CSV.parse(File.read(data_dir+'/PostRegions.tsv'), :headers => true, :col_sep => "\t").each_with_index do |row,i|
      row = makeRowSafe(row)
      PostRegion.where(subcode: row['PostRegion']).each do |post_region|
        old_region =  post_region.region
        new_region = regions[row['Region']]
        if old_region.name != new_region.name
          puts("Changing #{post_region.name} from #{old_region.name} to #{new_region.name}")
          post_region.region_id = new_region.id
          post_region.save!
        end
      end
    end
  end
end

# PERIODIC DB-RELATED TASKS IN PRODUCTION
# (Updating records automatically when certain conditions are satisfied,
#  or cleaning out data which is no longer valid or needed)

namespace :flair do
  desc "Error Test"
  task :error_test => [:environment] do
    raise 'Error Test to see if exception_notification-rake gem is working'
  end

  # This task should not be run too frequently! If multiple instances run at the same time,
  #   duplicate notifications will be sent out!
  desc "Send batched notification messages out"
  task :send_notifications => [:environment] do
    Notification.where("sent = false AND created_at < ?", 1.hour.ago).group_by(&:recipient).each do |recipient, notifications|
      message = StaffMailer.batched_update_for_employee(recipient.user, notifications)
      if Rails.env.production?
        begin
          SendMailJob.perform_later(message.to_yaml)
          notifications.each { |n| n.sent = true; n.save! }
        end
      elsif Rails.env.staging?
        message.to = 'error@appybara.com'
        message.cc = nil
        #message.bcc = ''
        begin
          SendMailJob.perform_later(message.to_yaml)
          notifications.each { |n| n.sent = true; n.save! }
        end
      else
        begin
          puts "*** E-mail sent:"
          puts message.to_yaml
          puts "***"
          notifications.each { |n| n.sent = true; n.save! }
        end
      end
    end
  end

  desc "Change status for Events which are starting today"
  task :mark_happening_events => [:environment] do
    Event.where("DATE_START = ? AND STATUS != 'CANCELLED' AND STATUS != 'BOOKING'", Date.today).each do |event|
      event.update_column(:status, 'HAPPENING')
    end
  end

  desc "Generated the ongoing tasks for events"
  task :add_tasks_for_ongoing_events => [:environment] do
    Event.where(date_start: Date.today, show_in_ongoing: true).where.not(office_manager_id: nil).each do |event|
      event.event_tasks.destroy_all
      beginning_of_the_week = Date.today.beginning_of_week
	    (1..4).each do
		    event.event_tasks.create(officer_id: event.office_manager_id, template_id: EventTaskTemplate.find_by_task('Event Admin').id, task: EventTaskTemplate.find_by_task('Event Admin').task, due_date: (beginning_of_the_week + 3.days).to_date)
        event.event_tasks.create(officer_id: event.office_manager_id, template_id: EventTaskTemplate.find_by_task("Confirm Team & FD'S").id, task: EventTaskTemplate.find_by_task("Confirm Team & FD'S").task, due_date: (beginning_of_the_week + 2.days).to_date)
        event.event_tasks.create(officer_id: event.office_manager_id, template_id: EventTaskTemplate.find_by_task("Send Email/Call backs").id, task: EventTaskTemplate.find_by_task("Send Email/Call backs").task, due_date: (beginning_of_the_week + 3.days).to_date)
        event.event_tasks.create(officer_id: event.office_manager_id, template_id: EventTaskTemplate.find_by_task("Re-asses Next Team").id, task: EventTaskTemplate.find_by_task("Re-asses Next Team").task, due_date: (beginning_of_the_week + 4.days).to_date)
        beginning_of_the_week = beginning_of_the_week + 7.days
	    end
    end
  end

  desc "Interview reminder email"
  task :interview_reminder_email => [:environment] do
    time_from = Time.now + 11.hours + 56.minutes
    time_to = Time.now + 12.hours
    date_from = time_from.to_date
    date_to = time_to.to_date
    interviews = Interview.includes(:prospect, interview_slot: :interview_block).where(interview_blocks: {date: date_from..date_to}).where("interview_slots.time_start BETWEEN ? AND ?", time_from, time_to)

    interviews.each do |interview|
      user = interview.prospect
      interview_date = interview.date.strftime('%A %d %B')
      interview_time = interview.time_type
      send_mail(StaffMailer.auto_reminder_email_for_interview_booking_time(user, interview_date, interview_time))
    end
  end

  desc "Change status for Events which finished yesterday"
  task :mark_finished_events => [:environment] do
    Event.where("current_date > date_end AND status <> 'FINISHED' AND status <> 'CLOSED' AND status <> 'CANCELLED'").each do |event|
      puts "Changing to finished at #{Time.now()} with event #{event.name} (#{event.id}) which finishes at #{event.date_end}"
      event.update_column(:status, 'FINISHED')
    end
  end

  desc "Update Next Active Date for Open Events"
  task :update_next_active_date_for_open_events => [:environment] do
    Event.where("STATUS <> 'CLOSED' AND STATUS <> 'OPENED'").each do |event|
      event.update_next_active_date
      event.save
    end
  end

  desc "Remove old gig requests"
  task :remove_old_gig_requests => [:environment] do
    Event.where(status: ['FINISHED', 'CANCELLED', 'CLOSED']).each do |event|
      event.gig_requests.destroy_all
    end
  end

  desc "Remove old sent notifications"
  task :remove_old_sent_notifications => [:environment] do
    Notification.where("sent = true AND created_at < ?", 1.month.ago).destroy_all
  end

  desc "Change status for Interviews which finished yesterday"
  task :mark_finished_bulk_interviews => [:environment] do
    BulkInterview.where("current_date > date_end AND status <> 'FINISHED' AND status <> 'CLOSED' AND status <> 'CANCELLED'").each do |bulk_interview|
      bulk_interview.update_column(:status, 'FINISHED')
    end
  end

  desc "Delete past interviews"
  task :delete_past_interviews => [:environment] do
    Interview.joins(:interview_slot, "JOIN interview_blocks ON interview_slots.interview_block_id = interview_blocks.id").where("current_date > interview_blocks.date").destroy_all
  end

  desc "Change status for Prospects who have worked a gig, but not in the past 3 years"
  desc "The also should not have gig requests, and have not logged in the past 6 months"
  task :mark_old_employees_as_sleepers => [:environment] do
    Prospect.joins(:gigs).joins("JOIN events ON gigs.event_id = events.id").left_outer_joins(:gig_requests).where(gig_requests: { prospect_id: nil }).where(
      "prospects.status = 'EMPLOYEE' AND (prospects.last_login IS NULL OR prospects.last_login < ?)", 6.months.ago).group(
      'prospects.id').having('MAX(events.date_end) < ?', 2.years.ago).each do |prospect|
      prospect.update_column(:status, 'SLEEPER')
      # Don't keep ID for sleepers
      prospect.update_column(:id_sighted, nil)
      prospect.scanned_ids.destroy_all
    end
  end

  desc "Delete Old Prospects"
  task :delete_old_prospects => [:environment] do
    # TODO: Send the new "Your account has been deactivated" email when auto-deleted. (CLEANOUT)

    ##### For all the following, only delete if they haven't logged in in the past 6 months
    ##### Delete employees whom haven't worked a gig, and registered more than two years ago
    Prospect.where(status: 'EMPLOYEE').includes(:gigs).where(gigs: { prospect_id: nil}).where(
      'prospects.created_at < ? AND (prospects.last_login IS NULL OR prospects.last_login < ?)', 2.years.ago, 6.months.ago).destroy_all
    ##### Delete active applicants who registered more than two years ago
    Prospect.where(status: 'APPLICANT', applicant_status: ['ACTIVE', 'LIVE']).where(
      'prospects.created_at < ? AND (prospects.last_login IS NULL or prospects.last_login < ?)', 2.years.ago, 6.months.ago).destroy_all
    ##### Delete holding applicants who registered more than one year ago
    Prospect.where(status: 'APPLICANT', applicant_status: 'HOLDING').where(
      'prospects.created_at < ? AND (prospects.last_login IS NULL or prospects.last_login < ?)', 1.year.ago, 6.months.ago).destroy_all
    ##### Delete unconfirmed applicants who registered more than one month ago
    Prospect.where(status: 'APPLICANT', applicant_status: 'UNCONFIRMED').where('prospects.created_at < ?', 1.month.ago).destroy_all
  end

  desc "Set 'start date' for Prospects who just worked their first event today"
  task :set_new_employee_start_dates => [:environment] do
    Prospect.joins(:gigs).joins("JOIN events ON gigs.event_id = events.id").where(
      "events.status <> 'CANCELLED' AND current_date >= events.date_start").where(
      "prospects.date_start IS NULL AND prospects.status = 'EMPLOYEE'").each do |prospect|
      # We don't set employee 'start date' when they are first hired,
      #   because Events are rescheduled sometimes
      # Instead, we wait until their first day of work has FINISHED
      prospect.update_column(:date_start, Date.today)
    end
  end

  desc "Clear tax choice for employees who have not worked in 2 months"
  task :clear_tax_choice_after_2_months_inactive => [:environment] do
    Prospect.joins(:gigs).joins("JOIN events ON gigs.event_id = events.id").where(
      "prospects.tax_choice IS NOT NULL AND prospects.last_login < ?", 2.months.ago).group('prospects.id').having(
      'MAX(events.date_end) < ?', 2.months.ago).each do |prospect|
      prospect.update(tax_choice: nil, date_tax_choice: nil)
    end
  end

  desc "Remove old Deletion records"
  task :cleanup_deletions_table => [:environment] do
    # destroy_all doesn't work here, because Deletion doesn't have an 'id' field
    Deletion.where('updated_at < ?', 1.week.ago).delete_all
  end

  desc "Remove references to photos that no longer exist"
  task :remove_broken_photo_references => [:environment] do
    Prospect.where.not(photo: nil).each do |prospect|
      photo_path = File.join(Flair::Application.config.shared_dir, 'prospect_photos', prospect.photo)
      prospect.update_column(:photo, nil) unless File.exists? photo_path
    end
  end

  desc "Create Invoices"
  task :create_invoices_for_previous_tax_week => [:environment] do
    tax_week = TaxWeek.where('date_start <= ? AND ? <= date_end', Date.today-7, Date.today-7).first
    Event.where("date_start <= ? AND date_end >= ? AND status != 'CANCELLED'", tax_week.date_end, tax_week.date_start).each { |e| e.invoice_if_needed(tax_week)}
  end

  desc "Move Event Tasks Forward"
  task :move_incomplete_event_tasks_forward => [:environment] do
    EventTask.where('completed IS FALSE AND due_date < ?', Date.today).each do |event_task|
      event_task.due_date = Date.today
      event_task.save
    end
  end

  desc "Generate Tax Weeks for upcoming year"
  task :generate_tax_weeks => [:environment] do
    require 'brightpay'
    include Brightpay

    tax_years = {}
    ((Date.today.year)..(Date.today.year+1)).each do |year|
       date = Date.new(year, 4, 6)
       tyh = date_to_taxyear(date)
       tax_years[year] = {}
       tax_years[year][:date_start] = tyh[:start]
       tax_years[year][:date_end] = tyh[:end]
    end

    ##### Create TaxYears
    tax_years.each do |year,tyh|
      if TaxYear.where(date_start: tyh[:date_start], date_end: tyh[:date_end]).none?
        ty = TaxYear.new
        ty.date_start = tyh[:date_start]
        ty.date_end = tyh[:date_end]
        ty.save
      end
    end

    ##### Calculate and Create TaxWeeks
    TaxYear.all.each do |ty|
      ty.date_start.upto(ty.date_end) do |date|
        twh = Brightpay::date_to_taxweek(date)
        if TaxWeek.where(date_start: twh[:start], date_end: twh[:end]).none?
          tw = TaxWeek.new
          tw.date_start = twh[:start]
          tw.date_end = twh[:end]
          tw.week = twh[:week]
          tw.tax_year_id = ty.id
          tw.save
        end
      end
    end
  end

  ##### Microsoft seems to update these around 1am PST.
  ##### So, recommend running this task around 10am UK time to get the latest report.
  desc "Add SNDS Admin Log Entry"
  task :add_snds_admin_log_entry => [:environment] do
    require 'open-uri'
    require 'csv'

    url = "https://sendersupport.olc.protection.outlook.com/snds/data.aspx?key=0288cdb3-8cbf-4028-e74b-99875e55c441"
    download = open(url)
    CSV.new(download).each do |line|
      data = {
        ip_address: line[0],
        activity_start: line[1],
        activity_end: line[2],
        rcpt_commands: line[3],
        data_commands: line[4],
        message_recipients: line[5],
        filter_result: line[6],
        complaint_rate: line[7],
        trap_message_period: line[8],
        trap_hits: line[9],
        sample_HELO: line[10],
        sample_MAIL_FROM: line[11],
        comments: line[12]
      }
      AdminLogEntry.create!(type: 'snds_report', data: data)
    end
  end

  desc "Sends mail to update the share_code"
  task :mail_share_code, [:year] => :environment do |task, args|
    year = args[:year].presence || 2022
    @prospects = Prospect.distinct
                  .other_nationality
                  .left_joins(gig_requests: :event)
                  .left_joins(gigs: :event)
                  .where('prospects.share_code IS NULL AND EXTRACT(YEAR FROM prospects.created_at) = ? AND
                         (events.date_end > ? OR events_gigs.date_start > ?)', year, Date.current, Date.current)
    @prospects.find_each.with_index do |prospect, count|
      puts "prospect #{count}"
      send_mail(StaffMailer.request_share_code(prospect))
    end
    nil
  end

  desc "Display the emails from the people that would receive the share_code email"
  task :preview_mail_share_code, [:year] => :environment do |task, args|
    year = args[:year].presence || 2022
    @prospects = Prospect.distinct
                  .other_nationality
                  .left_joins(gig_requests: :event)
                  .left_joins(gigs: :event)
                  .where('prospects.share_code IS NULL AND EXTRACT(YEAR FROM prospects.created_at) = ? AND
                         (events.date_end > ? OR events_gigs.date_start > ?)', year, Date.current, Date.current)
    emails = []
    @prospects.find_each.with_index do |prospect, count|
      emails << prospect.email
    end
    
    puts emails
  end

  desc "Restore id_sighted from ROW nationality"
  task :restore_id_sighted => :environment do
    require 'csv'
    csv = CSV.read('script/approved_dates.csv', col_sep: ";") 
    changed = []
    csv.each do |csv|
      prospect = Prospect.find(csv[0])
      if prospect.id_sighted.blank? && prospect.share_code.blank? 
        prospect.update(id_sighted: csv[1])
        changed << csv[0]
      end
    end

    p changed
  end

  desc "PREVIEW remove id_sighted"
  task :preview_remove_id_sighted => :environment do
    @prospects = Prospect.distinct
                  .other_nationality
                  .left_joins(gig_requests: :event)
                  .left_joins(gigs: :event)
                  .where('id_sighted < ? AND prospects.share_code IS NULL AND
                         (events.date_end > ? OR events_gigs.date_start > ?)', '2022-03-28'.to_date, Date.current, Date.current)
                  .pluck(:email, :created_at).map { |data| [data[0], data[1].year] }

    p @prospects
  end

  desc "remove id_sighted"
  task :remove_id_sighted => :environment do
    @prospects = Prospect.distinct
                  .other_nationality
                  .left_joins(gig_requests: :event)
                  .left_joins(gigs: :event)
                  .where('id_sighted < ? AND prospects.share_code IS NULL AND
                         (events.date_end > ? OR events_gigs.date_start > ?)', '2022-03-28'.to_date, Date.current, Date.current)

    @prospects.find_each.with_index do |prospect, count|
      prospect.update(id_sighted: nil, id_type: 'Work/Residency Visa')
      send_mail(StaffMailer.request_share_code(prospect))
      puts count
    end
  end
end


def send_mail(*messages)
  if Rails.env.production?
    SendMailJob.perform_later(*messages.map(&:to_yaml))
  else
    messages.each do |m|
      m.to = 'error@appybara.com'
      m.cc = nil
      #m.bcc = ''
    end
    SendMailJob.perform_later(*messages.map(&:to_yaml))
  end
  # SendMailJob.perform_later(*messages.map(&:to_yaml))
  # if Rails.env.production?
  #   SendMailJob.perform_later(*messages.map(&:to_yaml))
  # elsif Rails.env.staging?
  #   messages.each do |m|
  #     m.to = 'error@appybara.com'
  #     m.cc = nil
  #     #m.bcc = ''
  #   end
  #   SendMailJob.perform_later(*messages.map(&:to_yaml))
  # else
  #   messages.each do |message|
  #     puts "*** E-mail sent:"
  #     puts message.to_yaml
  #     puts "***"
  #   end
  # end
end
