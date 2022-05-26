set :output, '/home/deploy/cron.log'

every 30.minutes do
  rake "flair:send_notifications"
end

every 5.minutes do
  rake "flair:interview_reminder_email"
end

every 1.day, at: '11:50pm' do
  rake "flair:set_new_employee_start_dates"
  rake "db:backup"
end

every 1.day, at: '1:01am' do
  rake "flair:mark_happening_events"
  rake "flair:mark_finished_events"
  rake "flair:update_next_active_date_for_open_events"
  rake "flair:remove_old_gig_requests"
  rake "flair:mark_finished_bulk_interviews"
  rake "flair:delete_past_interviews"
  rake "flair:mark_active_employees"
  rake "flair:mark_old_employees_as_sleepers"
  rake "flair:delete_old_prospects"
  rake "flair:clear_tax_choice_after_2_months_inactive"
  rake "flair:fix_culture_counter_counts"
  rake "flair:remove_old_sent_notifications"
end

every 1.day, at: '12:00am' do
  rake "flair:add_tasks_for_ongoing_events"
end

every 1.day, at: '10:00am' do
  rake "flair:add_snds_admin_log_entry"
end

every :sunday, at: '2:00am' do
  rake "flair:cleanup_deletions_table"
  rake "flair:backup_letsencrypt"
end

every :monday, at: '2:00am' do
  rake "flair:create_invoices_for_previous_tax_week"
  rake "flair:move_incomplete_event_tasks_forward"
end

every 1.month, at: '1:30am' do
  rake "flair:generate_tax_weeks"
end
