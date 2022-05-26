class CreateAssignmentEmailTemplate < ActiveRecord::Migration[5.1]
  def change
    create_table :assignment_email_templates do |t|
      t.belongs_to :event, index: true
      t.string :name, null: false, default: "Default", unique: true
      t.text :office_message, default: ""
      t.text :arrival_time, default: ""
      t.text :meeting_location, default: ""
      t.string :meeting_location_coords, default: ""
      t.text :on_site_contact, default: ""
      t.text :contact_number, default: ""
      t.text :uniform, default: ""
      t.text :welfare, default: ""
      t.text :transport, default: ""
      t.text :details, default: ""
      t.text :additional_info, default: ""
      t.timestamps null: false
    end
  end
end
