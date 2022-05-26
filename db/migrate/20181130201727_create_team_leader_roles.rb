class CreateTeamLeaderRoles < ActiveRecord::Migration[5.2]
  def change
    create_table :team_leader_roles do |t|
      t.references :event, foreign_key: true, null: false
      t.bigint :user_id, null: false
      t.string :user_type, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :team_leader_roles, :updated_at
  end
end
