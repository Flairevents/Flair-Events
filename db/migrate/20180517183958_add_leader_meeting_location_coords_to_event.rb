class AddLeaderMeetingLocationCoordsToEvent < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :leader_meeting_location_coords, :string
  end
end
