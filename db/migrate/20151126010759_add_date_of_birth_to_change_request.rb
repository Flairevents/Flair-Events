class AddDateOfBirthToChangeRequest < ActiveRecord::Migration
  def up
    add_column :change_requests, :date_of_birth, :date
  end
  def down
    remove_column :change_requests, :date_of_birth
  end
end
