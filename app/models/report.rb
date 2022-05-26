require 'csv'
require 'write_xlsx'
require 'prawn'

class Report < ApplicationRecord
  serialize :fields, JSON

  validates_uniqueness_of :name

  def query(row_ids)
    query = case self.table
    when 'assignments'
      Assignment.joins(:event).joins(:job).joins(:location).joins(:shift)
    when 'clients'
      Client.joins("LEFT OUTER JOIN client_contacts on client_contacts.id = clients.primary_client_contact_id")
    when 'event_tasks'
      EventTask.left_joins(:event, :officer, :template)
    when 'gigs'
      Gig.joins(:prospect).joins(:event).joins(
        "LEFT OUTER JOIN prospects_avg_ratings ON gigs.prospect_id = prospects_avg_ratings.prospect_id").joins(
        "LEFT OUTER JOIN countries ON prospects.nationality_id = countries.id")
    when 'gig_assignments'
      GigAssignment.joins(:assignment).joins(:gig).joins(
        "LEFT OUTER JOIN jobs ON assignments.job_id = jobs.id").joins(
        "LEFT OUTER JOIN locations ON assignments.location_id = locations.id").joins(
        "LEFT OUTER JOIN shifts ON assignments.shift_id = shifts.id").joins(
        "LEFT OUTER JOIN prospects ON gigs.prospect_id = prospects.id").joins(
        "LEFT OUTER JOIN events ON gigs.event_id = events.id").joins(
        "LEFT OUTER JOIN gig_tags on gig_tags.gig_id = gigs.id").joins(
        "LEFT OUTER JOIN tags on tags.id = gig_tags.tag_id").group('gig_assignments.id, prospects.id, jobs.name, shifts.date, shifts.time_start, shifts.time_end, locations.name, gigs.notes')
    when 'gig_requests'
       GigRequest.joins(:prospect).joins(:event).joins(
         "LEFT OUTER JOIN countries ON prospects.nationality_id = countries.id")
    when 'events'
      Event.joins(:event_category)
    when 'pay_weeks'
      PayWeek.joins(:prospect).joins(
        "LEFT OUTER JOIN events ON pay_weeks.event_id = events.id").joins(
        "LEFT OUTER JOIN gigs ON gigs.prospect_id = prospects.id AND gigs.event_id = events.id").joins(
        "LEFT OUTER JOIN gig_assignments ON gig_assignments.gig_id = gigs.id").joins(
        "LEFT OUTER JOIN assignments ON gig_assignments.assignment_id = assignments.id").joins(
        "LEFT OUTER JOIN jobs ON assignments.job_id = jobs.id").joins(
        "LEFT OUTER JOIN locations ON assignments.location_id = locations.id").joins(
        "LEFT OUTER JOIN shifts ON assignments.shift_id = shifts.id")
    when 'timesheet_entries'
      TimesheetEntry.joins(:gig_assignment).joins(
        "LEFT OUTER JOIN gigs ON gig_assignments.gig_id = gigs.id").joins(
        "LEFT OUTER JOIN prospects ON gigs.prospect_id = prospects.id").joins(
        "LEFT OUTER JOIN assignments ON gig_assignments.assignment_id = assignments.id").joins(
        "LEFT OUTER JOIN jobs ON assignments.job_id = jobs.id").joins(
        "LEFT OUTER JOIN locations ON assignments.location_id = locations.id").joins(
        "LEFT OUTER JOIN shifts ON assignments.shift_id = shifts.id")
    when 'invoices'
      Invoice.joins(:event_client).joins(:tax_week).joins(
        "LEFT OUTER JOIN tax_years ON tax_years.id = tax_weeks.tax_year_id").joins(
        "LEFT OUTER JOIN clients ON clients.id = event_clients.client_id").joins(
        "LEFT OUTER JOIN events ON events.id = event_clients.event_id").joins(
        "LEFT OUTER JOIN bookings ON bookings.event_client_id = event_clients.id")
    else
      self.table.singularize.capitalize.constantize
    end

    query.where(id: row_ids)
  end

  ListColumn = Struct.new(:attr_name, :display_name, :select, :type, :sum, :width, keyword_init: true)

  def columns
    @columns ||= case self.table
    when 'prospects'
      [
        ListColumn.new(attr_name: :name,         display_name: 'Name',      type: :string, select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :email,        display_name: 'E-mail',    type: :string, select: 'prospects.email'),
        ListColumn.new(attr_name: :mobile_no,    display_name: 'Mobile',    type: :phone,  select: 'prospects.mobile_no'),
        ListColumn.new(attr_name: :home_no,      display_name: 'Home',      type: :phone,  select: 'prospects.home_no'),
        ListColumn.new(attr_name: :emergency_no, display_name: 'Emergency', type: :phone,  select: 'prospects.emergency_no'),
        ListColumn.new(attr_name: :gender,       display_name: 'Gender',    type: :string, select: 'prospects.gender'),
        ListColumn.new(attr_name: :tax_choice,   display_name: 'Tax Choice', type: :string, select: 'prospects.tax_choice'),
        ListColumn.new(attr_name: :ni_number,    display_name: 'NI Number', type: :string, select: 'prospects.ni_number'),
        ListColumn.new(attr_name: :id_number,    display_name: 'ID Number', type: :string, select: 'prospects.id_number')
      ]
    when 'event_tasks'
      [
        ListColumn.new(attr_name: :due_date,       display_name: 'Due Date',       type: :date,  select: "event_tasks.due_date"),
        ListColumn.new(attr_name: :event_name,     display_name: 'Event',          type: :string,  select: 'events.name'),
        ListColumn.new(attr_name: :completed,      display_name: 'Done',           type: :boolean, select: 'event_tasks.completed'),
        ListColumn.new(attr_name: :task,           display_name: 'Task',           type: :string,  select: 'event_task_templates.task'),
        ListColumn.new(attr_name: :notes,          display_name: 'Notes',          type: :string,  select: 'event_tasks.notes'),
        ListColumn.new(attr_name: :office_manager, display_name: 'Office Manager', type: :string,  select: "officers.first_name || ', ' || officers.last_name")
      ]
    when 'clients'
      [
        ListColumn.new(attr_name: :active,                    display_name: 'Active',          type: :boolean, select: 'clients.active'),
        ListColumn.new(attr_name: :name,                      display_name: 'Name',            type: :string,  select: 'clients.name'),
        ListColumn.new(attr_name: :address,                   display_name: 'Address',         type: :string,  select: 'clients.address'),
        ListColumn.new(attr_name: :phone_no,                  display_name: 'Phone #',         type: :phone,   select: 'clients.phone_no'),
        ListColumn.new(attr_name: :email,                     display_name: 'Email',           type: :string,  select: 'clients.email'),
        ListColumn.new(attr_name: :primary_contact_name,      display_name: 'Primary Contact', type: :string,  select: "client_contacts.first_name || ' ' || client_contacts.last_name"),
        ListColumn.new(attr_name: :primary_contact_mobile_no, display_name: 'PC Mobile',       type: :string,  select: 'client_contacts.mobile_no'),
        ListColumn.new(attr_name: :primary_contact_email,     display_name: 'PC Email',        type: :string,  select: 'client_contacts.email'),
        ListColumn.new(attr_name: :notes,                     display_name: 'Notes',           type: :string,  select: 'clients.notes')
      ]
    when 'gigs'
      [
        ListColumn.new(attr_name: :name,               display_name: 'Name',              type: :string,  select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :tax_choice,         display_name: 'Tax Choice',        type: :string,  select: 'prospects.tax_choice'),
        ListColumn.new(attr_name: :has_tax,            display_name: 'Tax?',              type: :boolean, select: 'prospects.tax_choice IS NOT NULL'),
        ListColumn.new(attr_name: :has_ni,             display_name: 'NI?',               type: :boolean, select: 'prospects.ni_number IS NOT NULL'),
        ListColumn.new(attr_name: :has_id,             display_name: 'ID?',               type: :boolean, select: "prospects.id_number IS NOT NULL AND prospects.id_type IS NOT NULL AND prospects.id_sighted IS NOT NULL AND (prospects.id_type <> 'Pass Visa' OR (prospects.visa_number IS NOT NULL AND (prospects.visa_expiry IS NULL OR prospects.visa_expiry >= current_date))) AND (prospects.id_type <> 'Work/Residency Visa' OR ((prospects.visa_number IS NOT NULL OR prospects.share_code IS NOT NULL) AND (prospects.visa_expiry IS NULL OR prospects.visa_expiry >= current_date)))"),
        ListColumn.new(attr_name: :has_dob,            display_name: 'DOB?',              type: :boolean, select: 'prospects.date_of_birth IS NOT NULL'),
        ListColumn.new(attr_name: :has_bank,           display_name: 'Bank?',             type: :boolean, select: 'prospects.bank_sort_code IS NOT NULL AND prospects.bank_account_no IS NOT NULL'),
        ListColumn.new(attr_name: :email,              display_name: 'E-mail Address',    type: :string,  select: 'prospects.email'),
        ListColumn.new(attr_name: :mobile_no,          display_name: 'Mobile',            type: :phone,   select: 'prospects.mobile_no'),
        ListColumn.new(attr_name: :home_no,            display_name: 'Home',              type: :phone,   select: 'prospects.home_no'),
        ListColumn.new(attr_name: :emergency_no,       display_name: 'Emergency',         type: :phone,   select: 'prospects.emergency_no'),
        ListColumn.new(attr_name: :bank_sort_code,     display_name: 'Bank Sort Code',    type: :string,  select: 'prospects.bank_sort_code'),
        ListColumn.new(attr_name: :bank_account_no,    display_name: 'Bank Account #',    type: :string,  select: 'prospects.bank_account_no'),
        ListColumn.new(attr_name: :bank_name,          display_name: 'Bank Account Name', type: :string,  select: 'prospects.bank_account_name'),
        ListColumn.new(attr_name: :first_name,         display_name: 'First Name',        type: :string,  select: 'prospects.first_name'),
        ListColumn.new(attr_name: :last_name,          display_name: 'Last Name',         type: :string,  select: 'prospects.last_name'),
        ListColumn.new(attr_name: :avg_rating,         display_name: 'Avg. Rating',       type: :number,  select: "to_char(prospects_avg_ratings.avg_rating, '9.00')"),
        ListColumn.new(attr_name: :prospect_notes,     display_name: 'Notes',             type: :string,  select: 'prospects.notes'),
        ListColumn.new(attr_name: :date_of_birth,      display_name: 'Date of Birth',     type: :date,    select: "to_char(prospects.date_of_birth, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :id_type,            display_name: 'ID Type',           type: :string,  select: 'prospects.id_type'),
        ListColumn.new(attr_name: :id_number,          display_name: 'ID Number',         type: :string,  select: 'prospects.id_number'),
        ListColumn.new(attr_name: :ni_number,          display_name: 'NI Number',         type: :string,  select: 'prospects.ni_number'),
        ListColumn.new(attr_name: :visa_number,        display_name: 'Visa Number',       type: :string,  select: 'prospects.visa_number'),
        ListColumn.new(attr_name: :visa_expiry,        display_name: 'Visa Expiry',       type: :date,    select: "to_char(prospects.visa_expiry, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :nationality,        display_name: 'Nationality',       type: :string,  select: 'countries.name'),
        ListColumn.new(attr_name: :address,            display_name: 'Address',           type: :string,  select: 'prospects.address'),
        ListColumn.new(attr_name: :post_code,          display_name: 'Post Code',         type: :string,  select: 'prospects.post_code'),
        ListColumn.new(attr_name: :gender,             display_name: 'Gender',            type: :string,  select: 'prospects.gender'),
        ListColumn.new(attr_name: :bar_experience,     display_name: 'Bar Exp',           type: :string,  select: 'CASE prospects.bar_experience WHEN \'Full\' THEN \'F\' WHEN \'Part\' THEN \'P\' WHEN \'None\' THEN \'X\' ELSE prospects.bar_experience END'),
        ListColumn.new(attr_name: :bar_license_type,   display_name: 'Lic. Type',         type: :string,  select: 'CASE prospects.bar_license_type WHEN \'SCLPS_2_HR_TRAINING\' THEN \'S\' WHEN \'SCOTTISH_PERSONAL_LICENSE\' THEN \'SL\' WHEN \'ENGLISH_PERSONAL_LICENSE\' THEN \'EL\' WHEN \'SCREEN_SHOT_OF_SCLPS\' THEN \'SS\' ELSE prospects.bar_license_type END'),
        ListColumn.new(attr_name: :bar_license_no,     display_name: 'Lic. #',            type: :string,  select: 'prospects.bar_license_no'),
        ListColumn.new(attr_name: :bar_license_expiry, display_name: 'Lic. Expiry',       type: :date,    select: "to_char(prospects.bar_license_expiry, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :training_type,      display_name: 'Training',          type: :string,  select: 'CASE prospects.training_type WHEN \'HealthAndSafety\' THEN \'HS\' WHEN \'FoodSafety\' THEN \'FS\' WHEN \'Both\' THEN \'B\' ELSE prospects.training_type END'),
        ListColumn.new(attr_name: :event_name,         display_name: 'Event Name',        type: :string,  select: 'events.name')
      ]
    when 'assignments'
      [
        ListColumn.new(attr_name: :location,           display_name: 'Location',    type: :string,  select: 'locations.name'),
        ListColumn.new(attr_name: :job_name,           display_name: 'Job',         type: :string,  select: 'jobs.name'),
        ListColumn.new(attr_name: :date,               display_name: 'Date',        type: :date,    select: "to_char(shifts.date, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :shift_start,        display_name: 'Shift Start', type: :time,    select: "to_char(shifts.time_start, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :shift_end,          display_name: 'Shift End',   type: :time,    select: "to_char(shifts.time_end, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :staff_confirmed,    display_name: 'Confirmed',   type: :number,  select: 'confirmed_staff_count'),
        ListColumn.new(attr_name: :staff_assigned,     display_name: 'Assigned',    type: :number,  select: 'staff_count'),
        ListColumn.new(attr_name: :staff_needed,       display_name: 'Needed',      type: :number,  select: 'assignments.staff_needed')
      ]
    when 'gig_assignments'
      [
        ListColumn.new(attr_name: :name,               display_name: 'Name',        type: :string,  select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :job_name,           display_name: 'Job',         type: :string,  select: 'jobs.name'),
        ListColumn.new(attr_name: :tag,                display_name: 'Tag',         type: :string,  select: "string_agg(tags.name, ', ' ORDER BY tags.name)"),
        ListColumn.new(attr_name: :location,           display_name: 'Location',    type: :string,  select: 'locations.name'),
        ListColumn.new(attr_name: :date,               display_name: 'Date',        type: :date,    select: "to_char(shifts.date, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :shift_start,        display_name: 'Shift Start', type: :time,    select: "to_char(shifts.time_start, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :shift_end,          display_name: 'Shift End',   type: :time,    select: "to_char(shifts.time_end, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :event_name,         display_name: 'Event Name',  type: :string,  select: 'events.name'),
        ListColumn.new(attr_name: :notes,              display_name: 'Notes',       type: :string,  select: 'gigs.notes')
      ]
    when 'gig_requests'
      [
        ListColumn.new(attr_name: :name,               display_name: 'Name',              type: :string,  select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :tax_choice,         display_name: 'Tax Choice',        type: :string,  select: 'prospects.tax_choice'),
        ListColumn.new(attr_name: :has_tax,            display_name: 'Tax?',              type: :boolean, select: 'prospects.tax_choice IS NOT NULL'),
        ListColumn.new(attr_name: :has_ni,             display_name: 'NI?',               type: :boolean, select: 'prospects.ni_number IS NOT NULL'),
        ListColumn.new(attr_name: :has_id,             display_name: 'ID?',               type: :boolean, select: "prospects.id_number IS NOT NULL AND prospects.id_type IS NOT NULL AND prospects.id_sighted IS NOT NULL AND (prospects.id_type <> 'Pass Visa' OR (prospects.visa_number IS NOT NULL AND (prospects.visa_expiry IS NULL OR prospects.visa_expiry >= current_date))) AND (prospects.id_type <> 'Work/Residency Visa' OR ((prospects.visa_number IS NOT NULL OR prospects.share_code IS NOT NULL) AND (prospects.visa_expiry IS NULL OR prospects.visa_expiry >= current_date)))"),
        ListColumn.new(attr_name: :has_dob,            display_name: 'DOB?',              type: :boolean, select: 'prospects.date_of_birth IS NOT NULL'),
        ListColumn.new(attr_name: :has_bank,           display_name: 'Bank?',             type: :boolean, select: 'prospects.bank_sort_code IS NOT NULL AND prospects.bank_account_no IS NOT NULL'),
        ListColumn.new(attr_name: :email,              display_name: 'E-mail Address',    type: :string,  select: 'prospects.email'),
        ListColumn.new(attr_name: :mobile_no,          display_name: 'Mobile',            type: :phone,   select: 'prospects.mobile_no'),
        ListColumn.new(attr_name: :home_no,            display_name: 'Home',              type: :phone,   select: 'prospects.home_no'),
        ListColumn.new(attr_name: :emergency_no,       display_name: 'Emergency',         type: :phone,   select: 'prospects.emergency_no'),
        ListColumn.new(attr_name: :bank_sort_code,     display_name: 'Bank Sort Code',    type: :string,  select: 'prospects.bank_sort_code'),
        ListColumn.new(attr_name: :bank_account_no,    display_name: 'Bank Account #',    type: :string,  select: 'prospects.bank_account_no'),
        ListColumn.new(attr_name: :bank_name,          display_name: 'Bank Account Name', type: :string,  select: 'prospects.bank_account_name'),
        ListColumn.new(attr_name: :first_name,         display_name: 'First Name',        type: :string,  select: 'prospects.first_name'),
        ListColumn.new(attr_name: :last_name,          display_name: 'Last Name',         type: :string,  select: 'prospects.last_name'),
        ListColumn.new(attr_name: :avg_rating,         display_name: 'Avg. Rating',       type: :number,  select: "to_char(prospects_avg_ratings.avg_rating, '9.00')"),
        ListColumn.new(attr_name: :prospect_notes,     display_name: 'Notes',             type: :string,  select: 'prospects.notes'),
        ListColumn.new(attr_name: :date_of_birth,      display_name: 'Date of Birth',     type: :date,    select: "to_char(prospects.date_of_birth, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :id_type,            display_name: 'ID Type',           type: :string,  select: 'prospects.id_type'),
        ListColumn.new(attr_name: :id_number,          display_name: 'ID Number',         type: :string,  select: 'prospects.id_number'),
        ListColumn.new(attr_name: :ni_number,          display_name: 'NI Number',         type: :string,  select: 'prospects.ni_number'),
        ListColumn.new(attr_name: :visa_number,        display_name: 'Visa Number',       type: :string,  select: 'prospects.visa_number'),
        ListColumn.new(attr_name: :visa_expiry,        display_name: 'Visa Expiry',       type: :date,    select: "to_char(prospects.visa_expiry, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :nationality,        display_name: 'Nationality',       type: :string,  select: 'countries.name'),
        ListColumn.new(attr_name: :address,            display_name: 'Address',           type: :string,  select: 'prospects.address'),
        ListColumn.new(attr_name: :post_code,          display_name: 'Post Code',         type: :string,  select: 'prospects.post_code'),
        ListColumn.new(attr_name: :gender,             display_name: 'Gender',            type: :string,  select: 'prospects.gender'),
        ListColumn.new(attr_name: :bar_experience,     display_name: 'Bar Exp',           type: :string,  select: 'CASE prospects.bar_experience WHEN \'Full\' THEN \'F\' WHEN \'Part\' THEN \'P\' WHEN \'None\' THEN \'X\' ELSE prospects.bar_experience END'),
        ListColumn.new(attr_name: :bar_license_type,   display_name: 'Lic. Type',         type: :string,  select: 'CASE prospects.bar_license_type WHEN \'SCLPS_2_HR_TRAINING\' THEN \'S\' WHEN \'SCOTTISH_PERSONAL_LICENSE\' THEN \'SL\' WHEN \'ENGLISH_PERSONAL_LICENSE\' THEN \'EL\' WHEN \'SCREEN_SHOT_OF_SCLPS\' THEN \'SS\' ELSE prospects.bar_license_type END'),
        ListColumn.new(attr_name: :bar_license_no,     display_name: 'Lic. #',            type: :string,  select: 'prospects.bar_license_no'),
        ListColumn.new(attr_name: :bar_license_expiry, display_name: 'Lic. Expiry',       type: :date,    select: "to_char(prospects.bar_license_expiry, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :training_type,      display_name: 'Training',          type: :string,  select: 'CASE prospects.training_type WHEN \'HealthAndSafety\' THEN \'HS\' WHEN \'FoodSafety\' THEN \'FS\' WHEN \'Both\' THEN \'B\' ELSE prospects.training_type END'),
        ListColumn.new(attr_name: :event_name,         display_name: 'Event Name',        type: :string,  select: 'events.name')
      ]
    when 'pay_weeks'
      [
        ListColumn.new(attr_name: :name,            display_name: 'Name',           type: :string,  select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :first_name,      display_name: 'First Name',     type: :string,  select: "prospects.first_name"),
        ListColumn.new(attr_name: :last_name,       display_name: 'Last Name',      type: :string,  select: "prospects.last_name"),
        ListColumn.new(attr_name: :monday,          display_name: 'M',              type: :number,  select: 'pay_weeks.monday'),
        ListColumn.new(attr_name: :tuesday,         display_name: 'T',              type: :number,  select: 'pay_weeks.tuesday'),
        ListColumn.new(attr_name: :wednesday,       display_name: 'W',              type: :number,  select: 'pay_weeks.wednesday'),
        ListColumn.new(attr_name: :thursday,        display_name: 'T',              type: :number,  select: 'pay_weeks.thursday'),
        ListColumn.new(attr_name: :friday,          display_name: 'F',              type: :number,  select: 'pay_weeks.friday'),
        ListColumn.new(attr_name: :saturday,        display_name: 'S',              type: :number,  select: 'pay_weeks.saturday'),
        ListColumn.new(attr_name: :sunday,          display_name: 'S',              type: :number,  select: 'pay_weeks.sunday'),
        ListColumn.new(attr_name: :rate,            display_name: 'Rate',           type: :number,  select: 'pay_weeks.rate'),
        ListColumn.new(attr_name: :total_hours,     display_name: 'Total Hrs',      type: :number,  select: 'pay_weeks.monday + pay_weeks.tuesday + pay_weeks.wednesday + pay_weeks.thursday + pay_weeks.friday + pay_weeks.saturday + pay_weeks.sunday'),
        ListColumn.new(attr_name: :allowance,       display_name: 'Allow',          type: :number,  select: 'pay_weeks.allowance'),
        ListColumn.new(attr_name: :deduction,       display_name: 'Deduct',         type: :number,  select: 'pay_weeks.deduction'),
        ListColumn.new(attr_name: :total_pay,       display_name: 'Total Pay',      type: :number,  select: 'pay_weeks.rate * (pay_weeks.monday + pay_weeks.tuesday + pay_weeks.wednesday + pay_weeks.thursday + pay_weeks.friday + pay_weeks.saturday + pay_weeks.sunday)'),
        ListColumn.new(attr_name: :job,             display_name: 'Job',            type: :string,  select: 'jobs.name'),
        ListColumn.new(attr_name: :location,        display_name: 'Location',       type: :string,  select: 'locations.name'),
        ListColumn.new(attr_name: :shift,           display_name: 'Shift',          type: :string,  select: "shifts.time_start || '-' || shifts.time_end"),
        ListColumn.new(attr_name: :event,           display_name: 'Event',          type: :string,  select: 'events.name'),
        ListColumn.new(attr_name: :bank_sort_code,  display_name: 'Bank Sort Code', type: :string,  select: 'prospects.bank_sort_code'),
        ListColumn.new(attr_name: :bank_account_no, display_name: 'Bank Account #', type: :string,  select: 'prospects.bank_account_no'),
        ListColumn.new(attr_name: :payment_method,  display_name: 'Bank Payment',   type: :boolean, select: "prospects.bank_sort_code IS NOT NULL AND prospects.bank_account_no IS NOT NULL AND prospects.bank_account_name IS NOT NULL AND prospects.id_sighted IS NOT NULL")
      ]
    when 'timesheet_entries'
      [
        ListColumn.new(attr_name: :name,          display_name: 'Name',     type: :string,  select: "prospects.last_name || ', ' || prospects.first_name"),
        ListColumn.new(attr_name: :job,           display_name: 'Job',      type: :string,  select: 'jobs.name'),
        ListColumn.new(attr_name: :location,      display_name: 'Location', type: :string,  select: 'locations.name'),
        ListColumn.new(attr_name: :date,          display_name: 'Date',     type: :date,    select: "to_char(shifts.date, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :time_start,    display_name: 'Start',    type: :time,    select: "to_char(timesheet_entries.time_start, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :time_end,      display_name: 'End',      type: :time,    select: "to_char(timesheet_entries.time_end, 'HH24:MI:SS.MS')"),
        ListColumn.new(attr_name: :total_hours,   display_name: 'Total',    type: :number,  select: "EXTRACT(epoch FROM (CASE WHEN (timesheet_entries.time_end > timesheet_entries.time_start) THEN (timesheet_entries.time_end - timesheet_entries.time_start) ELSE (timesheet_entries.time_end - timesheet_entries.time_start + interval '24' hour) END))/3600.0", sum: true, width: 7),
        ListColumn.new(attr_name: :break_minutes, display_name: 'Break',    type: :number,  select: "round((break_minutes/60.0)::numeric, 2)"),
        ListColumn.new(attr_name: :net_hours,     display_name: 'Net',      type: :number,  select: "EXTRACT(epoch FROM (CASE WHEN (timesheet_entries.time_end > timesheet_entries.time_start) THEN (timesheet_entries.time_end - timesheet_entries.time_start - (interval '1' minute * (CASE WHEN break_minutes IS NOT NULL THEN break_minutes ELSE 0 END))) ELSE (timesheet_entries.time_end - timesheet_entries.time_start + interval '24' hour - (interval '1' minute * (CASE WHEN break_minutes IS NOT NULL THEN break_minutes ELSE 0 END))) END))/3600.0", sum: true, width: 7),
      ]
    when 'invoices'
      [
        ListColumn.new(attr_name: :client_name, display_name: 'Client',                  type: :string,  select: 'clients.name'),
        ListColumn.new(attr_name: :event_name,  display_name: 'Events',                  type: :string,  select: 'events.name'),
        ListColumn.new(attr_name: :event_dates, display_name: 'Event Dates',             type: :string,  select: "to_char(events.date_start, 'YYYY-MM-DD') || ' - ' || to_char(events.date_end, 'YYYY-MM-DD')"),
        ListColumn.new(attr_name: :status,      display_name: 'Status',                  type: :string,  select: 'invoices.status'),
        ListColumn.new(attr_name: :notes,       display_name: 'Booking Invoicing Notes', type: :string,  select: 'bookings.invoicing'),
        ListColumn.new(attr_name: :tax_week,    display_name: 'Tax Week',                type: :string,  select: "to_char(tax_years.date_start, 'YYYY') || '-' || to_char(tax_years.date_start, 'YYYY') || ' ' || tax_weeks.week || ': ' || to_char(tax_weeks.date_start, 'YYYY-MM-DD') || ' - ' || to_char(tax_weeks.date_end, 'YYYY-MM-DD')")
      ]
    end.select { |c| self.fields.include?(c.attr_name.to_s) }.sort_by { |c| self.fields.index(c.attr_name.to_s) }
  end

  def field_labels
    @columns.map(&:display_name)
  end

  def exec(row_ids)
    if valid?
      select_clause = "#{self.table}.id, " + columns.map { |c| "#{c.select} AS #{c.attr_name}" }.join(', ')
      recordset     = db.execute(query(row_ids).select(select_clause).to_sql).to_a

      # This is hacky, really an EventTask with nil task/template id should have a "custom" version rather than nil. anyways...
      # TODO: Extract the nil custom tasks into a proper template
      recordset.each do |record|
        record['task'] = "Custom" if record['task'].nil?
      end if self.table == 'event_tasks'

      columns.select { |c| c.type == 'boolean' }.each do |c|
        recordset.each do |record|
          bool = record[c.attr_name.to_s]
          record[c.attr_name.to_s] = (bool ? 'Y' : 'N')
        end
      end

      columns.select { |c| c.type == 'number' }.each do |c|
        recordset.each do |record|
          number = record[c.attr_name.to_s]
          record[c.attr_name.to_s] = number.to_f
        end
      end

      # Sort recordset according to order which given IDs were arranged in
      # We can't do this in SQL
      # (This means that whatever sort order the user has selected when viewing data in the client,
      #   the data will appear in the same order when downloaded as a report)
      order     = {}
      row_ids.each_with_index { |id,idx| order[id.to_i] = idx }
      recordset.to_a.sort_by! { |record| order[record['id']] }
    else
      raise "Invalid report"
    end
  end

  def to_csv(row_ids)
    recordset = exec(row_ids)

    result = ''
    csv = CSV.new(result)

    if row_numbers?
      csv << self.field_labels.unshift('')
      recordset.each_with_index do |record,idx|
        csv << fields.map { |k| record[k] }.unshift(idx + 1)
      end
    else
      csv << self.field_labels # header row
      recordset.each do |record|
        csv << fields.map { |k| record[k] }
      end
    end

    result
  end

  def self.format_workbook(wb)
    options = {
      bold:                               {bold: 1},
      bold_top:                           {bold: 1, valign: 'top'},
      bold_center:                        {bold: 1, align: 'center'},
      bold_center_smaller_border1_bottom: {wrap: 1, bold: 1, align: 'center', size: 11, bottom: 1},
      date_bold_top:                      {num_format: 'dd/mm/yyyy', bold: 1, valign: 'top'},
      date_border1:                       {num_format: 'dd/mm/yyyy', border: 1},
      field_label:                        {bold: 1, border: 1},
      field_label_bg_yellow:              {border: 1, bg_color: '#FFFF66'},
      field_label_bg_yellow_bold:         {border: 1, bg_color: '#FFFF66', bold: 1},
      field_label_bg_yellow_bold_center:  {border: 1, bg_color: '#FFFF66', bold: 1, align: 'center'},
      standard:                           {},
      time_border1:                       {num_format: 'h:mm', border: 1},
      time_duration:                      {num_format: '[h]:mm'},
      time_duration_border1:              {num_format: '[h]:mm', border: 1},
      invertcolor_border1:                {border: 1, color: 'white', bg_color: 'black'},
      
      bold_red_size_12:                   {bold: 1, color: 'red', size: 15},
      border1_center:                     {border: 1, align: 'center'}
    }

    options = options.merge(generate_border_variants_for_style(options[:standard], 'border1', 1))
    options = options.merge(generate_border_variants_for_style(options[:standard], 'border2', 2))
    options = options.merge(generate_double_border_variants_for_style(options[:standard], 'border1', 1, 'border2', 2))
    options = options.merge(generate_double_border_variants_for_style(options[:field_label_bg_yellow_bold_center], 'field_label_bg_yellow_bold_center', 1, 'border2', 2))

    formats = {}
    options.each do |format, options|
      ##### Scale the fonts from their default size. I initially setup to work with excel for Mac,
      ##### but windows uses larger fonts
      options[:size] ||= 12
      options[:size] -= 2
      ##### By default, always wrap
      options[:text_wrap] = 1
      formats[format] = wb.add_format(options)
    end

    formats 
  end

  def self.generate_border_variants_for_style(style, name, type)
    {
      name.to_sym                  => style.merge({border: type}),
      :"#{name}_bottom"            => style.merge({bottom: type}),
      :"#{name}_bottom_left"       => style.merge({bottom: type, left: type}),
      :"#{name}_bottom_right"      => style.merge({bottom: type, right: type}),
      :"#{name}_bottom_left_right" => style.merge({bottom: type, left: type, right: type}),
      :"#{name}_top"               => style.merge({top: type}),
      :"#{name}_top_left"          => style.merge({top: type, left: type}),
      :"#{name}_top_right"         => style.merge({top: type, right: type}),
      :"#{name}_top_left_right"    => style.merge({top: type, left: type, right: type}),
      :"#{name}_left"              => style.merge({left: type}),
      :"#{name}_right"             => style.merge({right: type})
    }
  end

  def self.generate_double_border_variants_for_style(style, name1, type1, name2, type2)
    {
      :"#{name1}_with_#{name2}_bottom"            => style.merge({bottom: type2, top: type1, left: type1, right: type1}),
      :"#{name1}_with_#{name2}_bottom_left"       => style.merge({bottom: type2, top: type1, left: type2, right: type1}),
      :"#{name1}_with_#{name2}_bottom_right"      => style.merge({bottom: type2, top: type1, left: type1, right: type2}),
      :"#{name1}_with_#{name2}_bottom_left_right" => style.merge({bottom: type2, top: type1, left: type2, right: type2}),
      :"#{name1}_with_#{name2}_top"               => style.merge({bottom: type1, top: type2, left: type1, right: type1}),
      :"#{name1}_with_#{name2}_top_left"          => style.merge({bottom: type1, top: type2, left: type2, right: type1}),
      :"#{name1}_with_#{name2}_top_right"         => style.merge({bottom: type1, top: type2, left: type1, right: type2}),
      :"#{name1}_with_#{name2}_top_left_right"    => style.merge({bottom: type1, top: type2, left: type2, right: type2}),
      :"#{name1}_with_#{name2}_left"              => style.merge({bottom: type1, top: type1, left: type2, right: type1}),
      :"#{name1}_with_#{name2}_right"             => style.merge({bottom: type1, top: type1, left: type1, right: type2})
    }
  end

  def to_xlsx(row_ids)
    io = StringIO.new
    wb = WriteXLSX.new(io)
    format = self.class.format_workbook(wb)
    add_xlsx_worksheets(wb, row_ids, format)
    wb.close
    io.string
  end

  def self.add_standard_footer(ws)
    footer = ''
    footer += '&L'+'Flair People Ltd:#SC453179'
    footer += '&C'+'Pg &P of &N'
    footer += '&R&G'
    ws.set_footer(footer, nil, {image_right: Rails.root.join('public', 'flair-people-logo-96dpi.jpg')})
  end

  def self.setup_worksheet(ws)
    ws.paper = 9 #A4
    ws.fit_to_pages(1,0)
  end

  def add_xlsx_worksheets(wb, row_ids, format, tab_color=nil)
    recordset = exec(row_ids)

    sheets = {}
    if worksheet_key.blank?
      sheets[print_name] = recordset
    else
      recordset.each do |record|
        key = (record[worksheet_key] || 'BLANK')
        sheets[key] ||= []
        sheets[key] << record
      end
    end

    hf_style = '&14&B'

    sheets.sort_by {|k,v| k }.each do |name, recordset|
      right_header =
        case self.table
        when 'event_tasks'
          EventTask.find(recordset.first['id']).event.display_name
        when 'gigs'
          Gig.find(recordset.first['id']).event.display_name
        when 'gig_assignments'
          GigAssignment.find(recordset.first['id']).gig.event.display_name
        when 'assignments'
          Assignment.find(recordset.first['id']).event.display_name
        when 'timesheet_entries'
          event = TimesheetEntry.find(recordset.first['id']).gig_assignment.gig.event
          "#{event.display_name} (#{Client.find(event.event_clients.pluck(:client_id)).pluck(:name).join(', ')})"
        else
          nil
        end

      header = ''
      header += '&L'+hf_style+self.print_name
      header += '&C'+hf_style+'&A' unless worksheet_key.blank?
      header += '&R'+hf_style+right_header if right_header

      sheet = wb.add_worksheet(name)
      sheet.tab_color = tab_color if tab_color
      sheet.set_header(header)
      self.class.add_standard_footer(sheet)

      # Print the header row on each page
      sheet.repeat_rows(0)

      col_offset = row_numbers? ? 1 : 0

      # Calculate Column Widths
      widths = []
      width_multiplier = 1
      recordset.each do |record|
        @columns.each_with_index do |listColumn,c|
          val = (record[listColumn.attr_name.to_s]||'').to_s

          width = listColumn.width ||
                  [listColumn.display_name.length,
                  case listColumn.type
                  when :time, :time_duration
                    5
                  when :phone
                    self.class.format_phone(val).length
                  else
                    val.length
                  end].max
          widths[c] = [widths[c]||0, width*width_multiplier].max
        end
      end
      widths.each_with_index do |width, c|
        sheet.set_column(c+col_offset,c+col_offset,width)
      end

      # Page Setup
      self.class.setup_worksheet(sheet)
      if widths.length > 0
        sheet.set_landscape if widths.reduce(:+) > 90
      end

      # Write Header Row
      if row_numbers?
        sheet.set_column(0,0,3)
        sheet.write_blank(0,0)
      end
      sheet.write_row(0,col_offset, field_labels, format[:field_label])

      # Write Records
      row=1
      recordset.each do |record|
        sheet.write_number(row,0,row, format[:border1]) if row_numbers
        @columns.each_with_index do |listColumn,c|
          val = record[listColumn.attr_name.to_s] || ''
          col = c+col_offset
          case listColumn.type
          when :number
            sheet.write_number(row, col, val, format[:border1])
          when :string
            sheet.write_string(row, col, val, format[:border1])
          when :boolean
            if val && !val.blank?
              sheet.write_string(row, col, '✓', format[:border1])
            else
              sheet.write_string(row, col, '✘', format[:invertcolor_border1])
            end
          when :phone
            sheet.write_string(row, col, self.class.format_phone(val), format[:border1])
          when :date
            sheet.write_date_time(row, col, val.blank? ? '' : val+'T', format[:date_border1])
          when :time
            sheet.write_date_time(row, col, val.blank? ? '' : 'T'+val, format[:time_border1])
          when :time_duration
            sheet.write_date_time(row, col, val.blank? ? '' : 'T'+val, format[:time_duration_border1])
          else
            raise "Unknown Type: #{listColumn.type}"
          end
        end
        row += 1
      end
      if @columns.select{|c| c.sum}.length > 1
        if row_numbers?
          sheet.write(row, 0, 'TOTAL', format[:bold])
        end
      end
      @columns.each_with_index do |listColumn,c|
        col = c+col_offset
        if listColumn.sum
          formula = ("=SUM(#{self.class.xl_rowcol_to_cell(1,col)}:#{self.class.xl_rowcol_to_cell(row-1,col)})")
          case listColumn.type
          when :number
            sheet.write_formula(row, col, formula, format[:standard])
          when :time_duration
            sheet.write_formula(row, col, formula, format[:time_duration])
          else
            raise "Cannot sum columns of type: #{listColumn.type}"
          end
        end
      end
    end
  end

  def self.format_phone(number)
    begin
      ph = Phoner::Phone.parse(number, country_code: '44')
    rescue
      number
    else
      if ph
        case ph.format('%A').length
        when 3
          Phoner::Phone.n1_length = 4
        when 4
          Phoner::Phone.n1_length = 3
        else
          Phoner::Phone.n1_length = 6
        end
        ph.format('%A %f %l')
      else
        number
      end
    end
  end

  # page sizes for PDFs...
  # this method may raise Prawn::Errors::CannotFit if table simply cannot fit on a A4 page
  def to_pdf(row_ids)
    recordset = exec(row_ids)
    array     = [field_labels.map { |f| "<b>#{f}</b>"}]
    if row_numbers?
      array[0].unshift('')
      array  += recordset.map.with_index { |record,i| fields.map { |k| record[k].to_s}.unshift(i+1) }
    else
      array  += recordset.map { |record| fields.map { |k| record[k].to_s }}
    end

    doc = Prawn::Document.new(page_size: 'A4')
    doc.font_size = 9
    doc.font_families.update("OpenSans" => {
      :normal => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
      :bold_italic => Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf")
    })
    doc.font "OpenSans"

    # first we must decide whether to use vertical or horizontal page layout
    # if there are many columns, and the data in the columns is wide, we use a horizontal layout
    # otherwise, we use a vertical layout (to save paper when printing)
    columns = array.transpose
    natural_width = columns.map do |col|
      col.map { |cell| doc.width_of(cell.to_s, inline_format: true) }.max
    end.reduce(0,&:+)

    if natural_width > 595.28
      doc = Prawn::Document.new(page_size: 'A4', page_layout: :landscape)
    end

    # draw letterhead
    doc.text("Flair Events", size: 16, style: :bold)
    doc.text(self.print_name, size: 14, style: :bold)
    doc.move_down(8)

    doc.table(array, header: true, cell_style: {inline_format: true, padding: 3, size: 9})
    doc.number_pages("Page <page> of <total>", at: [0, 0], align: :center)

    doc.go_to_page(1)
    doc.text_box("Generated at #{Time.now.strftime('%l:%M%P, %d/%m/%Y').strip}", at: [0, 0], align: :right, height: 50)

    doc.render
  end

  def self.xl_rowcol_to_cell(row, col, row_absolute = false, col_absolute = false)
    row += 1      # Change from 0-indexed to 1 indexed.
    col_str = xl_col_to_name(col, col_absolute)
    "#{col_str}#{absolute_char(row_absolute)}#{row}"
  end
  def self.absolute_char(absolute)
    absolute ? '$' : ''
  end
  def self.xl_col_to_name(col, col_absolute)
    col_str = ColName.instance.col_str(col)
    "#{absolute_char(col_absolute)}#{col_str}"
  end
end
