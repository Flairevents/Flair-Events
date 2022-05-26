class AddLeaderFlairPhoneNoToEvent < ActiveRecord::Migration[5.2]
  def change
    add_column :events, :leader_flair_phone_no, :string, default: "", null: false
  end
end
