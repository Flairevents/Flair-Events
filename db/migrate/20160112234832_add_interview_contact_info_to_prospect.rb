class AddInterviewContactInfoToProspect < ActiveRecord::Migration
  def up
    add_column :prospects, :prefers_phone, :boolean, default: false
    add_column :prospects, :prefers_facetime, :boolean, default: false
    add_column :prospects, :prefers_skype, :boolean, default: false
    add_column :prospects, :preferred_phone, :string
    add_column :prospects, :preferred_facetime, :string
    add_column :prospects, :preferred_skype, :string
    add_column :prospects, :preferred_contact_time, :string
    add_column :change_requests, :prefers_phone, :boolean
    add_column :change_requests, :prefers_facetime, :boolean
    add_column :change_requests, :prefers_skype, :boolean
    add_column :change_requests, :preferred_phone, :string
    add_column :change_requests, :preferred_facetime, :string
    add_column :change_requests, :preferred_skype, :string
  end
  def down
    remove_column :prospects, :prefers_phone
    remove_column :prospects, :prefers_facetime
    remove_column :prospects, :prefers_skype
    remove_column :prospects, :preferred_phone
    remove_column :prospects, :preferred_facetime
    remove_column :prospects, :preferred_skype
    remove_column :prospects, :preferred_contact_time
    remove_column :change_requests, :prefers_phone
    remove_column :change_requests, :prefers_facetime
    remove_column :change_requests, :prefers_skype
    remove_column :change_requests, :preferred_phone
    remove_column :change_requests, :preferred_facetime
    remove_column :change_requests, :preferred_skype
  end
end
