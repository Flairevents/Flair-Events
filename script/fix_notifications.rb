# Remove notifications for:
# -  events that have started or that don't exist
# - People who are now Deactivated, or Has Been
notification_ids_to_delete = []

Notification.where(type: :change_rq_approved).destroy_all

Notification.where(type: [:accepted, :rejected, :removed], sent: false).each do |notification|
  if (prospect = Prospect.find_by_id(notification.recipient.user_id)) && !%w(HAS_BEEN DEACTIVATED).include?(prospect.status) 
    new_event_ids = []
    event_ids = notification.data['event_ids']  
    # Only keep open events that exist
    event_ids = event_ids.select {|id| (event = Event.find_by_id(id)) && event.status == 'OPEN'}
    # Only keep events for which this person hasn't already received assignment emails
    event_ids = event_ids.select do |event_id|
      sent_email = false
      if gig = Gig.where(event_id: event_id, prospect_id: prospect.id).first
        GigTaxWeek.where(gig_id: gig.id).each do |gig_tax_week|
          sent_email = true if gig_tax_week.assignment_email_type
        end  
      end
      !sent_email 
    end

    if event_ids.length == 0
      notification_ids_to_delete << notification.id
    elsif notification.data['event_ids'] != event_ids
      notification.data['event_ids'] = event_ids
      notification.save
    end
  else
    notification_ids_to_delete << notification.id
  end 
end

Notification.where(id: notification_ids_to_delete).destroy_all
