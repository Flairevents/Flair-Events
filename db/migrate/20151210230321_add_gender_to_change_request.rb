class AddGenderToChangeRequest < ActiveRecord::Migration
  def up
    add_column :change_requests, :gender, :string
  end
  def down
    remove_column :change_requests, :gender
  end
end
