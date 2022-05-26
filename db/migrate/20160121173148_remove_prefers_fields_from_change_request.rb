class RemovePrefersFieldsFromChangeRequest < ActiveRecord::Migration
  def up
    remove_column :change_requests, :prefers_live
    remove_column :change_requests, :prefers_phone
    remove_column :change_requests, :prefers_facetime
    remove_column :change_requests, :prefers_skype
  end
end
