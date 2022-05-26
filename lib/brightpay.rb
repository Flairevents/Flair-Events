require 'csv'
require 'fileutils'
require 'zip'

module Brightpay
  ##### Generates csv files (zipped) in a given path
  ##### Returns path of .zip file if successful, otherwise nil
  def pay_weeks_to_brightpay(pay_weeks)
    columns_employee_details = ['Employee Code', 'Title', 'Surname', 'First Name', 'Gender', 'Date of Birth', 'National Insurance Number', 'Address1', 'Address2', 'Address3', 'Country', 'Postcode', 'TaxCode', 'National Insurance Table', 'Student Loan', 'Tax Form Tick', 'Irregular', 'Normal Hrs', 'Tax Basis', 'Payment Method', 'Bank Account Number', 'Bank Sort Code', 'Bank Name', 'Email', 'Joined', 'Start Date', 'Leave Date', 'Job Title', 'Pay Bank Ref', 'Nationality', 'Passport Number']
    columns_weekly_hours = ['Employee Code', 'Surname', 'First Name', 'Basic Hours', 'Hourly Rate', 'Description', 'Department']
    columns_weekly_hours_updated =['Employee Code', 'Surname', 'First Name', 'Basic Hours', 'Basic Rate', 'Description', 'TAX', 'NI', 'Pen', 'Emp Pen', 'HP Hours', 'HP Rate', 'Description ', 'TAX', 'NI', 'Pen', 'Emp Pen', 'Allowance']
    columns_allowance = ['Employee Code', 'Surname', 'First Name', 'Allowance', 'Description', 'After National Insurance', 'After Tax', 'After Pension']
    columns_deductions = ['Employee Code', 'Surname', 'First Name', 'Deduction', 'Description', 'Before National Insurance', 'Before Tax', 'After Pension']

    raise "pay_weeks must all be for the same week" if (pay_weeks.map { |pw| pw.tax_week_id}).uniq.length > 1

    pay_weeks = pay_weeks.select { |pay_week| pay_week.prospect.include_in_brightpay? && (!pay_week.job || pay_week.job.non_zero_rate?) }

    # Sort tax weeks by name (later put in a hash, okay because Ruby 1.9.2 and newer preserves hash order)
    pay_weeks = pay_weeks.sort_by { |pay_week| "#{pay_week.prospect.last_name}, #{pay_week.prospect.first_name}" }

    ##### Create a hash of Arrays with employee ID as the key
    ##### ie. hash[employee_id] = [tax_week1, tax_week2, tax_week3]
    pay_week_hash = Hash.new { |h,k| h[k] = [] }
    # updated_employee_details
    pay_week_hash_updated = Hash.new { |h,k| h[k] = [] }
    tax_week = TaxWeek.find(pay_weeks[0].tax_week_id)

    # We only export prospects details when they are added to payroll
    prospect_ids = PayrollActivity.where(tax_week_id: tax_week.id, action: 'ADDED').pluck(:prospect_id).uniq

    # Returners
    prospect_ids_returners = []
    tax_week_ids = this_years_tax_week_ids_up_to(tax_week)
    PayrollActivity.includes(:prospect).where(tax_week_id: tax_week.id, action: 'ADDED').each do |payroll_activity|
      if PayrollActivity.where(tax_week_id: tax_week_ids, prospect_id: payroll_activity.prospect_id, action: 'REMOVED').exists?
        prospect_ids_returners << payroll_activity.prospect.id
      end
    end
    
    # Get all prospects for updated for updated_employee_details
    @prospect_ids_changes = pay_week_details_changes_updated(tax_week.id)
    #  Get all the leavers
    prospect_ids_updated = prospect_ids + @prospect_ids_changes + prospect_ids_returners + PayrollActivity.includes(:prospect).where(tax_week_id: tax_week.id, action: 'REMOVED').pluck(:prospect_id).uniq

    #Removing Prospect Ids that having EXTERNAL Status
    #Refs: BP Report NO EXTERNAL STATUS
    # 742-bp-report-no-external-status
    # 818-bp-leavers-needs-start-coloum

    prospect_ids_with_external_status = Prospect.where(status:  "EXTERNAL").ids
    prospect_ids_updated = (prospect_ids_updated - prospect_ids_with_external_status).uniq

    pay_weeks.each do |pw|
      pay_week_hash[pw.prospect_id] << pay_week_to_hash(pw)
    end

    # Updated Employee details
    prospect_ids_updated.each do |prospect_id|
      prospect = Prospect.find(prospect_id)
      pay_week_hash_updated[prospect_id] << pay_week_to_hash_updated(prospect,tax_week)
    end

    root = "#{Flair::Application.config.shared_dir}/brightpay"
    Dir.mkdir root unless Dir.exists?(root)
    file_prefix = "#{root}/#{tax_week.tax_year.date_start.year}-#{tax_week.tax_year.date_end.year}_#{tax_week.week}"

    csv_file_info = [
      {path: "#{file_prefix}_employee_details.csv", headers: columns_employee_details, merge: [], filter: {key: 'Employee Code', values: prospect_ids }},
      {path: "#{file_prefix}_employee_details_updated.csv", headers: columns_employee_details, merge: [], filter: {key: 'Employee Code', values: prospect_ids_updated, updated: true }},
      {path: "#{file_prefix}_weekly_hours.csv",     headers: columns_weekly_hours},
      {path: "#{file_prefix}_weekly_hours_updated.csv",     headers: columns_weekly_hours_updated},
      {path: "#{file_prefix}_allowance.csv",        headers: columns_allowance,        merge: ['Allowance']},
      {path: "#{file_prefix}_deductions.csv",       headers: columns_deductions,       merge: ['Deduction']}
    ]
    csv_file_info.each do |cfi|
      if cfi[:path] == "#{file_prefix}_employee_details_updated.csv"
        create_csv(cfi[:path], cfi[:headers], pay_week_hash_updated, cfi[:merge], cfi[:filter])
      else
        create_csv(cfi[:path], cfi[:headers], pay_week_hash, cfi[:merge], cfi[:filter])
      end
    end

    zip_path = "#{file_prefix}_brightpay.zip"
    File.delete(zip_path) if File.exists?(zip_path)
    Zip::File.open(zip_path, Zip::File::CREATE) do |zf|
      csv_file_info.each do |cfi|
        zf.add(File.basename(cfi[:path]), cfi[:path])
      end
    end

    send_file(zip_path, disposition: 'attachment', filename: File.basename(zip_path))
  end

  ##### Send an array in merge_fields (can be blank), if you want to combine multiple
  ##### entries for a prospect into one row. Note: All values will be taken from the
  ##### first entry in the array, except for any fields in merge_fields which will be
  ##### added together
  def create_csv(path, column_headers, hash, merge_fields=nil, filter=nil)
    CSV.open(path, "wb") do |csv|
      csv << column_headers
      hash.each do |id,array|
        ##### If we have fields to merge, we'll merge all these fields into one entry.
        ##### Currently, merging just needs to be adding together the specified fields
        if merge_fields
          merge_fields.each do |field|
            array[0][field] = array.map { |pay_week| pay_week[field] }.sum
          end
          array = [array[0]]
        end

        array.each do |pay_week|
          if filter != nil
            if filter[:updated] == true 
              csv << column_headers.map { |key| pay_week[key] }
              next
            end
          end
          if !filter || filter[:values].include?(pay_week[filter[:key]])
            csv << column_headers.map { |key| pay_week[key] }
          end
        end
      end
    end
  end

  def pay_week_to_hash(pay_week)
    pay_week_hash = Hash.new { |_,key| raise "Key #{ key } is not valid" }

    pay_week_hash['Employee Code']             = pay_week.prospect.id
    pay_week_hash['Title']                     = pay_week.prospect.gender == 'M' ? 'Mr' : 'Ms'
    pay_week_hash['Surname']                   = pay_week.prospect.last_name
    pay_week_hash['First Name']                = pay_week.prospect.first_name
    pay_week_hash['Gender']                    = pay_week.prospect.gender
    pay_week_hash['Date of Birth']             = pay_week.prospect.date_of_birth
    pay_week_hash['National Insurance Number'] = pay_week.prospect.ni_number
    pay_week_hash['Address1']                  = pay_week.prospect.address
    pay_week_hash['Address2']                  = pay_week.prospect.address2
    pay_week_hash['Address3']                  = pay_week.prospect.city
    pay_week_hash['Country']                   = 'England' #prospect.country && prospect.country.capitalize
    pay_week_hash['Postcode']                  = pay_week.prospect.post_code
    pay_week_hash['TaxCode']                   = pay_week.tax_week.tax_year.tax_code_from_choice(pay_week.prospect.tax_choice)
    pay_week_hash['National Insurance Table']  = pay_week.prospect.age < 21 ? 'M': 'A'
    pay_week_hash['Student Loan']              = pay_week.prospect.student_loan ? 'TRUE' : 'FALSE'
    pay_week_hash['Tax Form Tick']             = pay_week.prospect.tax_choice
    pay_week_hash['Irregular']                 = 'TRUE'
    pay_week_hash['Normal Hrs']                = 'Other'
    pay_week_hash['Tax Basis']                 = 'TRUE'
    pay_week_hash['Payment Method']            = pay_week.prospect.payment_method
    pay_week_hash['Bank Account Number']       = pay_week.prospect.bank_account_no
    pay_week_hash['Bank Sort Code']            = pay_week.prospect.bank_sort_code
    pay_week_hash['Bank Name']                 = pay_week.prospect.bank_account_name
    pay_week_hash['Email']                     = pay_week.prospect.email
    pay_week_hash['Joined']                    = pay_week.prospect.date_start
    pay_week_hash['Start Date']                = pay_week.tax_week.date_start
    pay_week_hash['Leave Date']                = nil ##### Hard code to blank for now 
    pay_week_hash['Job Title']                 = 'Event Staff'
    pay_week_hash['Pay Bank Ref']              = 'Flair Events'
    pay_week_hash['Nationality']               = pay_week.prospect.nationality.try(:name) || ''
    pay_week_hash['Passport Number']           = pay_week.prospect.visa_number
    pay_week_hash['Description']               = pay_week.event.display_name        if pay_week.event
    pay_week_hash['Department']                = pay_week.event.event_category.name if pay_week.event
    pay_week_hash['After National Insurance']  = 'FALSE'
    pay_week_hash['After Tax']                 = 'FALSE'
    pay_week_hash['After Pension']             = 'FALSE'
    pay_week_hash['Before National Insurance'] = 'FALSE'
    pay_week_hash['Before Tax']                = 'FALSE'
    pay_week_hash['Before Pension']            = 'FALSE'
    pay_week_hash['TAX']                       = 'TRUE'
    pay_week_hash['NI']                        = 'TRUE'
    pay_week_hash['Pen']                       = 'TRUE'
    pay_week_hash['Emp Pen']                   = 'TRUE'

    pay_week_hash['HP Hours']                  = pay_week.monday + pay_week.tuesday + pay_week.wednesday + pay_week.thursday + pay_week.friday + pay_week.saturday + pay_week.sunday
    pay_week_hash['HP Rate']                   = pay_week.job.holiday_pay_for_person(pay_week.prospect, pay_week.tax_week.date_start)
    pay_week_hash['Description ']              = 'Holiday'
    pay_week_hash['Allowance']                 = pay_week.allowance
    pay_week_hash['Deduction']                 = pay_week.deduction
    pay_week_hash['Basic Hours']               = pay_week.monday + pay_week.tuesday + pay_week.wednesday + pay_week.thursday + pay_week.friday + pay_week.saturday + pay_week.sunday
    basic_rate                                 = pay_week.job.base_pay_for_person(pay_week.prospect, pay_week.tax_week.date_start).to_f
    pay_week_hash['Basic Rate']                = basic_rate.round(2)
    pay_week_hash['Hourly Rate']               = pay_week.rate
    pay_week_hash
  end

  def pay_week_to_hash_updated(prospect,tax_week)
    pay_week_hash = Hash.new { |_,key| raise "Key #{ key } is not valid" }

    pay_week_hash['Employee Code']             = prospect.id
    pay_week_hash['Title']                     = prospect.gender == 'M' ? 'Mr' : 'Ms'
    pay_week_hash['Surname']                   = prospect.last_name
    pay_week_hash['First Name']                = prospect.first_name
    pay_week_hash['Gender']                    = prospect.gender
    pay_week_hash['Date of Birth']             = prospect.date_of_birth
    pay_week_hash['National Insurance Number'] = prospect.ni_number
    pay_week_hash['Address1']                  = prospect.address
    pay_week_hash['Address2']                  = prospect.address2
    pay_week_hash['Address3']                  = prospect.city
    pay_week_hash['Country']                   = 'England' #prospect.country && prospect.country.capitalize
    pay_week_hash['Postcode']                  = prospect.post_code
    if prospect.tax_choice == nil
      pay_week_hash['TaxCode']                   = nil
    else
      pay_week_hash['TaxCode']                   = tax_week.tax_year.tax_code_from_choice(prospect.tax_choice)
    end
    pay_week_hash['National Insurance Table']  = prospect.age < 21 ? 'M': 'A'
    pay_week_hash['Student Loan']              = prospect.student_loan ? 'TRUE' : 'FALSE'
    pay_week_hash['Tax Form Tick']             = prospect.tax_choice
    pay_week_hash['Irregular']                 = 'TRUE'
    pay_week_hash['Normal Hrs']                = 'Other'
    pay_week_hash['Tax Basis']                 = 'TRUE'
    pay_week_hash['Payment Method']            = prospect.payment_method
    pay_week_hash['Bank Account Number']       = prospect.bank_account_no
    pay_week_hash['Bank Sort Code']            = prospect.bank_sort_code
    pay_week_hash['Bank Name']                 = prospect.bank_account_name
    pay_week_hash['Email']                     = prospect.email
    pay_week_hash['Joined']                    = prospect.date_start

    # Refs BP - Leavers needs most recent start date
    
    most_recent_start_date = PayrollActivity.where(prospect_id: prospect.id).last.tax_week.date_start rescue  nil
    current_prospect_payroll_activity = PayrollActivity.where(tax_week_id: tax_week.id, prospect_id: prospect.id).first

    if current_prospect_payroll_activity
      if PayrollActivity.where(tax_week_id: tax_week.id, prospect_id: prospect.id).first.action == 'REMOVED'
        pay_week_hash['Leave Date']                = tax_week.date_end.strftime('%d/%m/%Y') ##### Hard code to blank for now 
        pay_week_hash['Start Date']                = current_prospect_payroll_activity.tax_week.date_start rescue nil
      else
        pay_week_hash['Leave Date']                = nil ##### Hard code to blank for now 
        if @prospect_ids_changes.include?(prospect.id)
          pay_week_hash['Start Date']                = current_prospect_payroll_activity.tax_week.date_start rescue nil
        else
          pay_week_hash['Start Date']                = tax_week.date_start
        end
      end
    else
      pay_week_hash['Leave Date']                = nil ##### Hard code to blank for now 
      if @prospect_ids_changes.include?(prospect.id)
        pay_week_hash['Start Date']                = most_recent_start_date
      else
        pay_week_hash['Start Date']                = tax_week.date_start
      end
    end

    pay_week_hash['Job Title']                 = 'Event Staff'
    pay_week_hash['Pay Bank Ref']              = 'Flair Events'
    pay_week_hash['Nationality']               = prospect.nationality.try(:name) || ''
    pay_week_hash['Passport Number']           = prospect.visa_number
    pay_week_hash['After National Insurance']  = 'FALSE'
    pay_week_hash['After Tax']                 = 'FALSE'
    pay_week_hash['After Pension']             = 'FALSE'
    pay_week_hash['Before National Insurance'] = 'FALSE'
    pay_week_hash['Before Tax']                = 'FALSE'
    pay_week_hash['Before Pension']            = 'FALSE'
    pay_week_hash
  end

  private

  ########################################################################
  ########################################################################
  ########################################################################
  ########################################################################
  ########################################################################
  ##### The following routines are now only called on an "as needed" basis
  ##### when we need to add new tax years/weeks to the database
  ########################################################################
  ########################################################################
  ########################################################################
  ########################################################################
  ########################################################################

  ##############################################################
  ##### Public routines to redirect to legacy/new routines #####
  ##############################################################
  ##### <  Mar 28, 2016 is legacy
  ##### >= Mar 29, 2016 is new
  #####
  ##### Definitions:
  ##### "Tax Year": Year for this tax year (April 6 YYYY - April 5 YYYY+1)
  ##### "Tax Week": Week (1-53) of the tax year
  ##### "TaxWeek": Hash structure that contains the tax year/week/date_start/date_end.
  #####            New: year/week: based on paydate
  #####                 start/end: convenience dates indicating workweek
  #####            Legacy: All based on workweek
  ##### "Date": Date in a workweek
  ##### "Paydate": Date in which a workweek is paid

  private
  LEGACY_CUTOFF_DATE = Date.new(2016, 3, 27)

  public

  def tax_year_from_date(date)
    if date > LEGACY_CUTOFF_DATE
      tax_year_from_paydate(get_paydate_from_date(date))
    else
      tax_year_from_date_legacy(date)
    end
  end

  def date_to_taxyear(date)
    if date > LEGACY_CUTOFF_DATE
      taxyear_from_paydate(get_paydate_from_date(date))
    else
      raise "date_to_taxyear not implemented for legacy taxweeks"
    end
  end

  def date_to_taxweek(date)
    if date > LEGACY_CUTOFF_DATE
      taxweek_from_paydate(get_paydate_from_date(date))
    else
      date_to_taxweek_legacy(date)
    end
  end

  def tax_year_and_week_to_taxweek(tax_year, tax_week)
    if tax_year >= LEGACY_CUTOFF_DATE.year
      tax_year_and_week_to_taxweek_new(tax_year, tax_week)
    else
      tax_year_and_week_to_taxweek_legacy(tax_year, tax_week)
    end
  end

  def taxweeks_between_dates(start_date, end_date)
    if start_date > LEGACY_CUTOFF_DATE && end_date > LEGACY_CUTOFF_DATE
      taxweeks_between_dates_new(start_date, end_date)
    elsif start_date <= LEGACY_CUTOFF_DATE && end_date <= LEGACY_CUTOFF_DATE
      taxweeks_between_dates_legacy(start_date, end_date)
    else
      taxweeks_between_dates_legacy(start_date, LEGACY_CUTOFF_DATE) + taxweeks_between_dates_new(LEGACY_CUTOFF_DATE+1, end_date)
    end
  end

  private
  ########################
  ##### New Routines #####
  ########################
  ##### Tax Weeks are calculated based on paydates (matches Brightpay)

  ######################
  ##### DATE SETUP #####
  ######################
  ##### Change this section to alter:
  # Tax Year Start
  TAX_YEAR_START_MONTH = 4
  TAX_YEAR_START_DAY = 6
  # Days between 'last day of workweek' and 'payday'
  PAYDAY_OFFSET = 5
  # The day of the week for the payday (ie. Sun-Sat: 0-6)
  PAYDAY_WDAY = 5
  ######################
  ######################
  ######################

  def tax_year_from_paydate(paydate)
    raise "paydate must be a #{wday_to_string(PAYDAY_WDAY)}" unless paydate.wday == PAYDAY_WDAY
    paydate < tax_year_start(paydate.year) ? paydate.year-1 : paydate.year
  end

  def taxyear_from_paydate(paydate)
    raise "paydate must be a #{wday_to_string(PAYDAY_WDAY)}" unless paydate.wday == PAYDAY_WDAY
    tax_year = tax_year_from_paydate(paydate)
    date_start = taxweek_from_paydate(first_paydate_of_tax_year(tax_year))[:start]
    date_end = taxweek_from_paydate(first_paydate_of_tax_year(tax_year+1))[:start] - 1.day
    { year: tax_year, start: date_start, end: date_end}
  end

  def taxweek_from_paydate(paydate)
    raise "paydate must be a #{wday_to_string(PAYDAY_WDAY)}" unless paydate.wday == PAYDAY_WDAY
    tax_year = tax_year_from_paydate(paydate)
    tax_week = ((paydate - first_paydate_of_tax_year(tax_year)).to_i/7)+1
    { year: tax_year, week: tax_week, start: paydate-PAYDAY_OFFSET-6, end: paydate-PAYDAY_OFFSET }
  end

  def taxweeks_between_dates_new(start_date, end_date)
    taxweeks = []
    start_paydate = get_paydate_from_date(start_date)
    end_paydate = get_paydate_from_date(end_date)

    (start_paydate..end_paydate).step(7) do |date|
      taxweeks << taxweek_from_paydate(date)
    end
    taxweeks
  end

  def tax_year_and_week_to_taxweek_new(tax_year, tax_week)
    raise "tax_week must be between 1 and 53" unless tax_week >= 1 && tax_week <=53
    paydate = first_paydate_of_tax_year(tax_year) + (tax_week-1)*7
    { year: tax_year, week: tax_week, start: paydate-PAYDAY_OFFSET-6, end: paydate-PAYDAY_OFFSET }
  end

  def get_paydate_from_date(date)
    date + mon_to_sun_desc_wday(date) + PAYDAY_OFFSET
  end

  # Returns Mon-Sun: 6-0
  def mon_to_sun_desc_wday(date)
    wday = 7-date.wday
    wday == 7 ? 0 : wday
  end

  def tax_year_start(tax_year)
    Date.new(tax_year, TAX_YEAR_START_MONTH, TAX_YEAR_START_DAY)
  end

  def first_paydate_of_tax_year(tax_year)
     tax_year_start = tax_year_start(tax_year)
     wday = tax_year_start.wday

     if wday <= PAYDAY_WDAY
       tax_year_start + PAYDAY_WDAY - wday
     else
       tax_year_start + PAYDAY_WDAY - wday + 7
     end
  end

  def wday_to_string(wday)
    case wday
      when 0
        :sunday
      when 1
        :monday
      when 2
        :tuesday
      when 3
        :wednesday
      when 4
        :thursday
      when 5
        :friday
      when 6
        :saturday
    end
  end


  ###########################
  ##### Legacy Routines #####
  ###########################
  ##### Legacy routines are based on an incorrect spec.
  ##### Tax weeks are calculated based on workweek dates
  ##### They also create truncated first and last weeks to align with a Monday-Sunday week
  # def tax_end_year_from_date_legacy(date)
  #   # "Tax year" runs from previous year (ie. April 6 2012 to April 5, 2013)
  #   date <= Date.new(date.year, 4, 5) ? date.year : date.year + 1
  # end

  def tax_year_from_date_legacy(date)
    date <= Date.new(date.year, 4, 5) ? date.year-1 : date.year
  end

  def tax_year_and_week_to_taxweek_legacy(tax_year, tax_week)
    tax_year_start = Date.new(tax_year, 4, 6)
    tax_year_end   = Date.new(tax_year+1, 4, 5)

    delta = tax_year_start.wday > 0 ? (7-tax_year_start.wday) : 0
    next_week_start = tax_year_start+delta+1

    return { year: tax_year, week: 1, start: tax_year_start, end: next_week_start-1} if tax_week == 1

    (2..53).each do |week|
      next_week_start+=7
      return { year: tax_year, week: week, start: next_week_start-7, end: tax_year_end } if next_week_start >= tax_year_end
      return { year: tax_year, week: week, start: next_week_start-7, end: next_week_start-1 } if tax_week == week
    end
  end

  def date_to_taxweek_legacy(date)
    tax_year = tax_year_from_date_legacy(date)
    tax_year_start = Date.new(tax_year, 4, 6)
    tax_year_end   = Date.new(tax_year+1, 4, 5)

    #First tax week of the year goes from tax_year_start to the nearest sunday
    delta = tax_year_start.wday > 0 ? (7-tax_year_start.wday) : 0
    next_week_start = tax_year_start+delta+1

    return {year: tax_year_from_date_legacy(date), week: 1, start: tax_year_start, end: next_week_start-1} if date < next_week_start

    (2..53).each do |week|
      next_week_start+=7
      return { year: tax_year_from_date_legacy(date), week: week, start: next_week_start-7, end: tax_year_end }      if next_week_start >= tax_year_end
      return { year: tax_year_from_date_legacy(date), week: week, start: next_week_start-7, end: next_week_start-1 } if date < next_week_start
    end
    raise("Could not find appropriate tax week for #{date}")
  end

  # Send it the first and last days of a tax year for a tax year
  # Send it the first and last days of an event, etc
  # ie. tax_weeks_between_dates(Date.new(2013, 4, 1), Date.new(2013, 4, 7))
  # This routine always returns the dates of the full tax week
  def taxweeks_between_dates_legacy(start_date, end_date)
    tax_week_dates = []
    week_start = start_date
    week_end = nil
    end_date_found = false

    until end_date_found == true do
      tax_year_start = Date.new(week_start.year, 4, 6)
      ##### Tax week goes up to the closest Sunday
      ##### We'll adjust it later if we need to
      delta = week_start.wday > 0 ? (7-week_start.wday) : 0
      week_end = week_start + delta
      ##### If we crossed over a tax year, then clip at the end of the tax year
      week_end = tax_year_start-1 if (week_start < tax_year_start) && (week_end >= tax_year_start)
      ##### Shorter than a tax week, so make it shorter
      week_end = end_date if week_end > end_date
      ##### Add first_week
      twh = date_to_taxweek_legacy(week_start)
      tax_week_dates.push({year: twh[:year], week: twh[:week], start: twh[:start], end: twh[:end]})

      ##### Now that the start of the tax year is adjusted, just keep adding weeks normally
      ##### But stop once we've:
      #####  Crossed over into a new tax year
      #####  Reached the end date

      week_start = week_end + 1
      week_end = week_start + 6

      until week_end >= end_date do
        ##### If we are crossing over the end of a tax year, exit this small loop, and go back to the main loop
        ##### The start of the main loop will clean up the transition between tax years
        tax_year_start = Date.new(week_start.year, 4, 6)
        if week_start <= tax_year_start && week_end >= tax_year_start
          break
        end

        twh = date_to_taxweek_legacy(week_start)
        tax_week_dates.push({year: twh[:year], week: twh[:week], start: twh[:start], end: twh[:end]})
        week_start +=7
        week_end += 7
      end
      ##### We're finished when when gone to/past the end date
      if week_end >= end_date
        end_date_found = true
      end
    end
    ##### This check prevents bad data on single day events, and on events that end on the start of a week
    if end_date >= week_start
      twh = date_to_taxweek_legacy(week_start)
      tax_week_dates.push({year: twh[:year], week: twh[:week], start: twh[:start], end: twh[:end]})
    end
    tax_week_dates
  end

  def pay_week_details_changes_updated(tax_week_id)
    changes = []
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
            changes << p_id
          end
        end
      end
    end
    changes
  end
end
