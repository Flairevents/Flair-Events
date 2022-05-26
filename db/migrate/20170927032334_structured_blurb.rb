class StructuredBlurb < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :blurb, :blurb_legacy

    add_column :events, :blurb_tag_line,              :text, default: ''
    add_column :events, :blurb_tag_line_secondary,    :text, default: ''
    add_column :events, :blurb_general,               :text, default: ''
    add_column :events, :blurb_job_information,       :text, default: ''
    add_column :events, :blurb_shift_information,     :text, default: ''
    add_column :events, :blurb_wage_information,      :text, default: ''
    add_column :events, :blurb_uniform_information,   :text, default: ''
    add_column :events, :blurb_transport_information, :text, default: ''
    add_column :events, :blurb_sign_up_message,       :text, default: ''
  end
end
