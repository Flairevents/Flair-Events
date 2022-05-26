class AddEmailAssignmentFieldsToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :email_asgmt_on_site_contact, :string
    add_column :events, :email_asgmt_contact_number,  :string
    add_column :events, :email_asgmt_office_message,  :text
    add_column :events, :email_asgmt_details,         :text
    add_column :events, :email_asgmt_additional_info, :text
  end
end
