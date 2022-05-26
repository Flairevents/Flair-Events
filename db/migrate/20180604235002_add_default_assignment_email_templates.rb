class AddDefaultAssignmentEmailTemplates < ActiveRecord::Migration[5.1]
  def up
    event_ids = Event.pluck(:id)
    event_ids_done = AssignmentEmailTemplate.pluck(:event_id).uniq
    (event_ids - event_ids_done).each do |event_id|
      AssignmentEmailTemplate.create(event_id: event_id, name: 'Default')
    end
  end
  def down
    AssignmentEmailTemplate.where(
      name: 'Default',
        office_message: '',
        arrival_time: '',
        meeting_location: '',
        meeting_location_coords: '',
        on_site_contact: '',
        contact_number: '',
        uniform: '',
        welfare: '',
        transport: '',
        details: '',
        additional_info: ''
    ).destroy_all
  end
end
