class RenameTeamLeaderNoteColumnsOnEvents < ActiveRecord::Migration[5.1]
  def change
    rename_column :events, :team_leader_note_general,          :leader_general
    rename_column :events, :team_leader_note_meeting_location, :leader_meeting_location
    rename_column :events, :team_leader_note_accomodation,     :leader_accomodation
    rename_column :events, :team_leader_note_job_role,         :leader_job_role
    rename_column :events, :team_leader_note_arrival_time,     :leader_arrival_time
    rename_column :events, :team_leader_note_handbooks,        :leader_handbooks
    rename_column :events, :team_leader_note_staff_job_roles,  :leader_staff_job_roles
    rename_column :events, :team_leader_note_energy,           :leader_energy
    rename_column :events, :team_leader_note_uniform,          :leader_uniform
    rename_column :events, :team_leader_note_food,             :leader_food
    rename_column :events, :team_leader_note_transport,        :leader_transport
  end
end
