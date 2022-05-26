class TeamLeaderFields < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :team_leader_note_general,          :text, null: false, default: ''
    add_column :events, :team_leader_note_meeting_location, :text, null: false, default: ''
    add_column :events, :team_leader_note_accomodation,     :text, null: false, default: ''
    add_column :events, :team_leader_note_job_role,         :text, null: false, default: ''
    add_column :events, :team_leader_note_arrival_time,     :text, null: false, default: ''
    add_column :events, :team_leader_note_handbooks,        :text, null: false, default: ''
    add_column :events, :team_leader_note_staff_job_roles,  :text, null: false, default: ''
    add_column :events, :team_leader_note_energy,           :text, null: false, default: ''
    add_column :events, :team_leader_note_uniform,          :text, null: false, default: ''
    add_column :events, :team_leader_note_food,             :text, null: false, default: ''
    add_column :events, :team_leader_note_transport,        :text, null: false, default: ''
  end
end
