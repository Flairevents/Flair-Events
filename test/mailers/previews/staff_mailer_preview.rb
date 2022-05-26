# Preview all emails at http://localhost:3000/rails/mailers/admin_mailer
class StaffMailerPreview < ActionMailer::Preview
  def employee_profile_5
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_profile_5(prospect)
  end

  def employee_profile_10
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_profile_10(prospect)
  end

  def employee_profile_20
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_profile_20(prospect)
  end

  def employee_profile_deleted
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_deleted(prospect)
  end

  def employee_book_interview_5
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_book_interview_5(prospect)
  end

  def employee_book_interview_10
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_book_interview_10(prospect)
  end

  def employee_book_interview_20
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_book_interview_20(prospect)
  end

  def employee_book_interview_deleted
    prospect = Prospect.find_by(email: "krampuerto@gmail.com")

    StaffMailer.employee_book_interview_deleted(prospect)
  end

  def auto_email_for_interview_booking_time
    prospect = Prospect.find_by(email: "hello@hotmail.com")
    interview = Interview.where(prospect_id: prospect.id).last

    StaffMailer.auto_email_for_interview_booking_time(prospect, interview)
  end

  def auto_reminder_email_for_interview_booking_time
    prospect = Prospect.find_by(email: 'hello@hotmail.com')
    interview = Interview.where(prospect_id: prospect.id).last

    StaffMailer.auto_reminder_email_for_interview_booking_time(prospect, interview.date, interview.time_type)
  end

  def auto_reminder_email_for_interview_booking_time_missed
    prospect = Prospect.find_by(email: 'hello@hotmail.com')

    StaffMailer.auto_reminder_email_for_interview_booking_time_missed(prospect)
  end

  def applicant_accepted
    prospect = Prospect.find_by(email: 'krampuerto@gmail.com')

    StaffMailer.applicant_accepted(prospect)
  end
end
