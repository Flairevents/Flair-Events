class AddUpdatedAtIndexToNewerModels < ActiveRecord::Migration[5.1]
  def change
    add_index :clients, :updated_at
    add_index :client_contacts, :updated_at
    add_index :event_clients, :updated_at
    add_index :bookings, :updated_at
    add_index :assignments, :updated_at
    add_index :gig_assignments, :updated_at
    add_index :pay_weeks, :updated_at
    add_index :tax_years, :updated_at
    add_index :tax_weeks, :updated_at
    add_index :invoices, :updated_at
    add_index :bulk_interviews, :updated_at
    add_index :bulk_interview_events, :updated_at
    add_index :interview_blocks, :updated_at
    add_index :interview_slots, :updated_at
    add_index :interviews, :updated_at
    add_index :text_blocks, :updated_at
    add_index :faq_entries, :updated_at
    add_index :library_items, :updated_at
  end
end
