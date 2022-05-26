class PortClientContacts < ActiveRecord::Migration
  def change
    Client.all.each do |c|
      if !c.primary_contact_name.blank? && !c.primary_contact_email.blank?
        cc = ClientContact.new
        name_array = c.primary_contact_name.split(" ") 
        cc.first_name = name_array[0]
        cc.last_name = name_array[1..-1].join(" ")
        cc.email = c.primary_contact_email
        cc.mobile_no = c.primary_contact_mobile_no
        cc.client_id = c.id
        cc.save
        c.primary_client_contact_id = cc.id
        c.save
        EventClient.where(client_id: c.id).all.each do |ec|
          Booking.where(event_client: ec.id).all.each do |b|
            b.client_contact_id = cc.id
            b.save
          end
        end
      end
    end
  end
end
