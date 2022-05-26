class AssignmentEmailTemplateColumnsNotNull < ActiveRecord::Migration[5.2]
  def change
    # All of these columns have default values, so there is no need for them to
    #   ever be NULL
    # (Though they can hold blank strings)

    change_column_null :assignment_email_templates, :office_message,          false
    change_column_null :assignment_email_templates, :arrival_time,            false
    change_column_null :assignment_email_templates, :meeting_location,        false
    change_column_null :assignment_email_templates, :meeting_location_coords, false
    change_column_null :assignment_email_templates, :on_site_contact,         false
    change_column_null :assignment_email_templates, :contact_number,          false
    change_column_null :assignment_email_templates, :uniform,                 false
    change_column_null :assignment_email_templates, :welfare,                 false
    change_column_null :assignment_email_templates, :transport,               false
    change_column_null :assignment_email_templates, :details,                 false
    change_column_null :assignment_email_templates, :details,                 false
    change_column_null :assignment_email_templates, :additional_info,         false
  end
end
