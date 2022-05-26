class UpdateEventLeaderAndBlurbFields < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :leader_staff_arrival, :text, null: false, default: ''
    rename_column :events, :blurb_tag_line, :blurb_title
    rename_column :events, :blurb_tag_line_2, :blurb_subtitle
    rename_column :events, :blurb_general, :blurb_opening
    add_column :events, :blurb_closing, :text, default: ''
  end
end
