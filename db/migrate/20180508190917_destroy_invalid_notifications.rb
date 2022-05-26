class DestroyInvalidNotifications < ActiveRecord::Migration[5.1]
  def change
    notifications = Notification.where(sent: false, type: 'change_rq_approved').select {|n| !ChangeRequest.find_by_id(n.data['id'])}
    notifications.each {|n| n.destroy} 
  end
end
