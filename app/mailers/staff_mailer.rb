require 'set'

require 'icalendar'

class StaffMailer < ApplicationMailer
  #################################
  ##### EMAILS FOR APPLICANTS #####
  #################################

  def applicant_accepted(user)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    # @events = user.gigs.map(&:event)
    unsub_header(@person.account.unsubscribe_token)

    mail(to: user.email, subject: "#{@name}, You're Hired.")
  end

  def applicant_blacklisted(user, reason)
    @person = user
    @name   = user.first_name
    @reason = reason
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Flair Events has deleted your records")
  end

  ################################
  ##### EMAILS FOR EMPLOYEES #####
  ################################

  def batched_update_for_employee(user, notifications)
    return unless user.send_auto_emails?
    raise 'Batched notifications are only for Prospects' unless user.is_a?(Prospect)

    # We may want to let an employee know:
    # - They were not accepted to work on certain Events (rejected)
    # - They have been accepted to work on certain Events (accepted)
    # - They are no longer working on Events which they were previously informed of (removed)
    # - Their details change request was processed
    @updates = notifications.group_by(&:type)
    rejected_for = Set.new((@updates['rejected'] || []).mappend { |u| u.data['event_ids'].select {|id| Event.find_by_id id} })
    accepted_for = Set.new((@updates['accepted'] || []).mappend { |u| u.data['event_ids'].select {|id| Event.find_by_id id} })
    removed_from = Set.new((@updates['removed']  || []).mappend { |u| u.data['event_ids'].select {|id| Event.find_by_id id} })

    # If an employee was turned down to work at a certain Event, but before we can deliver
    #   the notification, the office staff changes and hires them, there is no need to tell
    #   them that they were rejected
    rejected_for.subtract(accepted_for)
    # If one is hired, but before we can deliver the notification, they are taken off the
    #   Event, there is no need to tell them that they were hired OR that they were
    #   subsequently removed
    hired_and_removed = accepted_for.intersection(removed_from)
    accepted_for.subtract(hired_and_removed)
    removed_from.subtract(hired_and_removed)
    # Note that the above code makes 'accepted' and 'removed' notifications cancel one another
    #   out. We do not check that the 'removed' notification actually came AFTER the 'accepted'
    #   notification -- that is assumed

    @rejected = Event.find(rejected_for.to_a)
    @accepted = Event.find(accepted_for.to_a)
    @removed    = Event.find(removed_from.to_a)

    @rejected_reasons = (@updates['rejected'] || []).map { |u| u.data['reason'] }.reject(&:blank?).uniq
    @removed_reasons    = (@updates['removed']    || []).map { |u| u.data['reason'] }.reject(&:blank?).uniq

    @person = user
    @name   = user.first_name

    update_types = [@rejected.size, @accepted.size, @removed.size].count { |n| !n.zero? }
    return if update_types.zero? # Nothing to inform user about

    subject = 'Updates on your selected Events'

    subject = if update_types == 1
      # If there is only one type of update included in this batched e-mail, we can use a very
      #   specific subject line:
      if !@rejected.empty?
        'Changes to your Event selection'
      elsif !@accepted.empty?
        if @accepted.length > 1
          "You are scheduled to work multiple events"
        else
          "You are scheduled to work at #{@accepted.map(&:display_name_with_location).to_sentence}"
        end
      elsif !@removed.empty?
        if @accepted.length > 1
          "You are no longer scheduled to work at these events"
        else
          "You are no longer scheduled to work at #{@removed.map(&:display_name_with_location).to_sentence}"
        end
      end
    end

    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: subject)
  end

  def employee_deactivated_account_contracts_worked(user, upcoming_gigs)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    @upcoming_gigs = upcoming_gigs
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Your account has been deactivated")
  end

  def auto_email_for_interview_booking_time(user, interview)
	  return unless user.send_auto_emails?

    @person = user
	  @name = user.first_name
    @interview = interview

    # @interview_date = interview.date.strftime('%A %d %B')
    # @interview_time = interview.time_start.strftime('%I:%M%p')
    interview_year =  interview.date.year
    interview_month =  interview.date.month
    interview_day = interview.date.day
    interview_time_hour = interview.time_start.hour
    interview_time_minutes = interview.time_start.min

    cal = Icalendar::Calendar.new
    event = Icalendar::Event.new
    event.dtstart = DateTime.civil(interview_year, interview_month, interview_day, interview_time_hour, interview_time_minutes)
    event.summary = "Interview Confirmation – Flair Event Staffing"
    cal.add_event(event)
    cal.publish
    attachments['events.ics'] = { mime_type: 'application/ics', content: cal.to_ical }
    unsub_header(@person.account.unsubscribe_token)

	  mail(to: user.email, subject: "#{@name} - Your Interview Details")
  end

  def auto_reminder_email_for_interview_booking_time(user ,interview_date, interview_time)
    return unless user.send_auto_emails?
    
    @name = user.first_name
    @interview_date = interview_date
    @interview_time = interview_time.downcase == 'morning' ? '10am-1pm' : (interview_time.downcase == 'afternoon' ? '12:30pm-4pm' : '4pm-7pm')
    @interview_slot = interview_time
    unsub_header(user.account.unsubscribe_token)

    mail(to: user.email, subject: "Jump into Flair's team today.")
  end

  def auto_reminder_email_for_interview_booking_time_missed(user)
    return unless user.send_auto_emails?

    @name = user.name
    unsub_header(user.account.unsubscribe_token)

    mail(to: user.email, subject: "Reschedule Your Interview")
  end

  def employee_deactivated_account_no_contracts_worked(user, upcoming_gigs)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    @upcoming_gigs = upcoming_gigs
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Your account has been deactivated")
  end

  def applicant_deactivated_due_to_inactivity(user)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Your account has been deactivated")
  end

  def employee_id_approved(user)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Flair Events has processed your ID scans")
  end

  def employee_id_rejected(user, reason)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    @reason = reason
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "There was a problem with your ID scans")
  end

  def photo_rejected(user)
    # Refs: Stop auto email for photo reject
    # https://trello.com/c/x6e6rhtq/911-stop-auto-email-for-photo-reject
    return if user.send_auto_emails?
    @person = user
    @name   = user.first_name
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "There was a problem with your photo")
  end

  def employee_blacklisted(user, reason)
    return unless user.send_auto_emails?
    @person = user
    @name   = user.first_name
    @reason = reason
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Flair Events has deleted your records")
  end

  #profile application reminder
  def employee_profile_5(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Book Your Telephone Interview")
  end

  def employee_profile_10(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Ready to apply for jobs? Book your telephone interview!")
  end

  def employee_profile_20(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Telephone interviews available every day this week")
  end

  def employee_profile_deleted(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "We have removed your details.")
  end

  #book interview reminder
  def employee_book_interview_5(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Last step, book your telephone interview")
  end

  def employee_book_interview_10(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Free for a telephone interview this week?")
  end

  def employee_book_interview_20(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Book an Interview and Find Flexible Jobs")
  end

  def employee_book_interview_deleted(user)
    @name = user.first_name
    account = user.account

    @unsub = account.unsubscribe_token
    unsub_header(@unsub)

    mail(to: user.email, subject: "Still Interested In Finding Flexible Work? Please Register Again")
  end

  #########################################################################################################
  ##### ALWAYS SEND THE FOLLOWING EMAILS REGARDLESS OF WHETHER THE USER NORMALLY RECEIVES AUTO-EMAILS #####
  #########################################################################################################

  def unsubscribe_acknowledgement(user)
    #Note: This mailer shares a view with lib/unsubscribe.rb (non-rails ruby script). Do any Railsy stuff (like base url) here
    @person = user
    @salutation = "Hi #{@person[:first_name]},"
    @base_url = Flair::Application.config.base_http_url
    @unsubscribe_url = "#{@base_url}/staff/unsubscribe?token=#{@person.account.unsubscribe_token}"
    unsub_header(@person.account.unsubscribe_token)
    mail(to: user.email, subject: "Please Finalize Your Unsubscribe Request")
  end

  def employee_assignment_details(user, data)
    @data = data
    @person = user
    unsub_header(user.account.unsubscribe_token)
    #attachments['shifts.ics'] = { mime_type: 'text/calendar', content: data[:icalendar].to_ical } if data[:icalendar]
    mail(to: user.email, subject: data[:subject])
  end

  def request_share_code(user)
    @name = user.first_name
    @unsub = user.account.unsubscribe_token
    unsub_header(@unsub)
    mail(to: user.email, subject: 'Flair needs your ‘Share Code’ – for your right to work please!')
  end
end
