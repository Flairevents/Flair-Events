class ChangeAllIdsToBigInt < ActiveRecord::Migration[5.2]
  def change
    to_change = [
      [:accounts,              [:id, :user_id]],
      [:assignments,           [:event_id, :job_id, :shift_id, :location_id]],
      [:bookings,              [:id, :event_client_id, :event_client_id, :client_contact_id]],
      [:bulk_interview_events, [:id, :bulk_interview_id, :event_id]],
      [:bulk_interviews,       [:id, :target_region_id]],
      [:change_requests,       [:id, :prospect_id]],
      [:client_contacts,       [:id, :client_id]],
      [:clients,               [:id, :primary_client_contact_id, :terms_client_contact_id, :safety_client_contact_id]],
      [:countries,             [:id]],
      [:deletions,             [:record_id]],
      [:details_history,       [:id, :prospect_id]],
      [:event_categories,      [:id]],
      [:event_clients,         [:id, :event_id, :client_id]],
      [:events,                [:id, :category_id, :invoice_frequency_start_tax_week_id, :leader_client_contact_id, :default_job_id, :default_assignment_id]],
      [:expenses,              [:event_id ]],
      [:faq_entries,           [:id]],
      [:gig_requests,          [:id, :prospect_id, :event_id, :gig_id]],
      [:gig_tags,              [:gig_id, :tag_id]],
      [:gig_tax_weeks,         [:assignment_email_template_id]],
      [:gigs,                  [:id, :prospect_id, :event_id, :job_id]],
      [:interview_blocks,      [:id, :bulk_interview_id]],
      [:interview_slots,       [:id, :interview_block_id]],
      [:interviews,            [:id, :prospect_id, :interview_slot_id]],
      [:invoices,              [:id, :event_client_id, :tax_week_id]], 
      [:jobs,                  [:id, :event_id]],
      [:library_items,         [:id]],
      [:locations,             [:id, :event_id]],
      [:notifications,         [:recipient_id]],
      [:officers,              [:id]],
      [:pay_week_details_histories, [:id, :prospect_id, :tax_week_id]],
      [:pay_weeks,             [:id, :tax_week_id, :job_id, :prospect_id, :event_id]],
      [:post_areas,            [:id, :post_region_id]],
      [:post_regions,          [:id, :region_id]],
      [:prospects,             [:id, :nationality_id]],
      [:questionnaires,        [:id, :prospect_id]],
      [:regions,               [:id]],
      [:reports,               [:id]],
      [:scanned_bar_licenses,  [:id, :prospect_id]],
      [:scanned_ids,           [:id, :prospect_id]],
      [:session_logs,          [:account_id]],
      [:shifts,                [:id, :event_id]],
      [:tags,                  [:id, :event_id]],
      [:tax_weeks,             [:id, :tax_year_id]],
      [:tax_years,             [:id]],
      [:text_blocks,           [:id]],
      [:time_clock_reports,    [:event_id, :tax_week_id]],
      [:time_clocks,           [:timesheet_id, :gig_assignment_id]],
      [:timesheet_entries,     [:gig_assignment_id, :tax_week_id, :pay_week_id, :time_clock_report_id]],
    ]
    reversible do |change|
      execute <<-SQL
        drop view if exists public.prospects_avg_ratings
      SQL

      to_change.each do |to_change|
        table = to_change[0]
        to_change[1].each do |column|
          change.up   { change_column table, column, :bigint}
          change.down { change_column table, column, :integer}
        end
      end

      execute <<-SQL
        CREATE VIEW public.prospects_avg_ratings AS
         SELECT prospects.id AS prospect_id,
           avg(gigs.rating) AS avg_rating
          FROM (public.prospects
            JOIN public.gigs ON ((prospects.id = gigs.prospect_id)))
         GROUP BY prospects.id;
      SQL
    end
  end
end
