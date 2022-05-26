class RemovedUnusedIdFieldsFromChangeRequest < ActiveRecord::Migration
  def up
    remove_column :change_requests, :id_type
    remove_column :change_requests, :id_number
    remove_column :change_requests, :visa_number
    remove_column :change_requests, :visa_expiry
    remove_column :change_requests, :accepted
  end

  def down
    add_column :change_requests, :id_type, :string
    add_column :change_requests, :id_number, :string
    add_column :change_requests, :visa_number, :string
    add_column :change_requests, :visa_expiry, :string
    add_column :change_requests, :accepted, :boolean,  null: false, default: false
  end
end
