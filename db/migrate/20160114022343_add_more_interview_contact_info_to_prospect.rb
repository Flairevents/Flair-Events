class AddMoreInterviewContactInfoToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :prefers_live, :boolean, default: false
    add_column :change_requests, :prefers_live, :boolean
  end
  def end
    remove_column :prospects, :prefers_live
    remove_column :change_requests, :prefers_live
  end
end
