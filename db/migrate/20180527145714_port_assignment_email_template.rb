class PortAssignmentEmailTemplate < ActiveRecord::Migration[5.1]
  def up
    add_column :gig_tax_weeks, :assignment_email_type, :string
    add_column :gig_tax_weeks, :assignment_email_template_id, :integer
    add_index  :gig_tax_weeks, :assignment_email_template_id
    GigTaxWeek.all.each do |gtw|
      if gtw.gig
        if gtw.sent_asgmt_email_full
          gtw.assignment_email_type = 'Full'
        elsif gtw.sent_asgmt_email_part
          gtw.assignment_email_type = 'Part'
        elsif gtw.sent_asgmt_email_confirm  
          gtw.assignment_email_type = 'Confirm'
        elsif gtw.sent_asgmt_email_info
          gtw.assignment_email_type = 'Info'
        end  

        unless assignment_email_template = AssignmentEmailTemplate.where(event_id: gtw.gig.event_id, name: 'Default').first
          e = gtw.gig.event
          assignment_email_template = AssignmentEmailTemplate.create(
            event_id: e.id,
            name: 'Default',
            on_site_contact:         e.email_asgmt_on_site_contact    ? e.email_asgmt_on_site_contact    : '',
            contact_number:          e.email_asgmt_contact_number     ? e.email_asgmt_contact_number     : '',
            office_message:          e.email_asgmt_office_message     ? e.email_asgmt_office_message     : '',
            details:                 e.email_asgmt_details            ? e.email_asgmt_details            : '',
            additional_info:         e.email_asgmt_additional_info    ? e.email_asgmt_additional_info    : '',
            arrival_time:            e.leader_staff_arrival           ? e.leader_staff_arrival           : '',
            welfare:                 e.leader_food                    ? e.leader_food                    : '',
            meeting_location:        e.leader_meeting_location        ? e.leader_meeting_location        : '',
            meeting_location_coords: e.leader_meeting_location_coords ? e.leader_meeting_location_coords : '',
            transport:               e.blurb_transport                ? e.blurb_transport                : '',
            uniform:                 e.blurb_transport                ? e.blurb_uniform                  : ''
          )
        end  

        gtw.assignment_email_template_id = assignment_email_template.id
        gtw.save!
      else
        gtw.destroy!
      end  
    end
    remove_column :gig_tax_weeks, :sent_asgmt_email_info  
    remove_column :gig_tax_weeks, :sent_asgmt_email_confirm
    remove_column :gig_tax_weeks, :sent_asgmt_email_part
    remove_column :gig_tax_weeks, :sent_asgmt_email_full
    remove_column :events, :email_asgmt_on_site_contact
    remove_column :events, :email_asgmt_contact_number
    remove_column :events, :email_asgmt_office_message
    remove_column :events, :email_asgmt_details
    remove_column :events, :email_asgmt_additional_info
  end

  def down
    add_column :gig_tax_weeks, :sent_asgmt_email_info, :boolean, null: false, default: false
    add_column :gig_tax_weeks, :sent_asgmt_email_confirm, :boolean, null: false, default: false
    add_column :gig_tax_weeks, :sent_asgmt_email_part, :boolean, null: false, default: false
    add_column :gig_tax_weeks, :sent_asgmt_email_full, :boolean, null: false, default: false
    GigTaxWeek.all.each do |gtw|
      case gtw.assignment_email_type
      when 'Full'
        gtw.sent_asgmt_email_full = true
      when 'Part'
        gtw.sent_asgmt_email_part = true
      when 'Confirm'
        gtw.sent_asgmt_email_confirm = true
      when 'Info'  
        gtw.sent_asgmt_email_info = true
      end
      gtw.save!
    end
    remove_column :gig_tax_weeks, :assignment_email_type
    remove_column :gig_tax_weeks, :assignment_email_template_id

    add_column :events, :email_asgmt_on_site_contact, :string
    add_column :events, :email_asgmt_contact_number, :string
    add_column :events, :email_asgmt_office_message, :string
    add_column :events, :email_asgmt_details, :string
    add_column :events, :email_asgmt_additional_info, :string

    AssignmentEmailTemplate.where(name: 'Default').each do |aet|
      e = Event.find(aet.event_id)
      e.email_asgmt_on_site_contact = aet.on_site_contact
      e.email_asgmt_contact_number  = aet.contact_number
      e.email_asgmt_office_message  = aet.office_message
      e.email_asgmt_details         = aet.details
      e.email_asgmt_additional_info = aet.additional_info
      e.save!
    end

    AssignmentEmailTemplate.destroy_all
  end  
end
