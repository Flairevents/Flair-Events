class RenameEventBlurbColumns < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :blurb_tag_line_secondary, :blurb_tag_line_2
    rename_column :events, :blurb_job_information, :blurb_job
    rename_column :events, :blurb_shift_information, :blurb_shift
    rename_column :events, :blurb_wage_information, :blurb_wage_additional
    rename_column :events, :blurb_uniform_information, :blurb_uniform
    rename_column :events, :blurb_transport_information, :blurb_transport
  end
end
