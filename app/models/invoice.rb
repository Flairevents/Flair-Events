require 'office_zone_sync'

class Invoice < ApplicationRecord
  include OfficeZoneSync

  belongs_to :tax_week
  belongs_to :event_client

  validates_presence_of :event_client_id, message: ": Must Select Client And Event"
  validates_presence_of :tax_week_id

  STATUSES = %w{NEW EMAILED SAGE}.freeze
  validates_inclusion_of :status, in: STATUSES

  before_save do |invoice|
    if invoice.status_changed?
      invoice.date_emailed = Date.today if invoice.status == 'EMAILED'
      invoice.date_emailed = nil if invoice.status == 'NEW'
    end

  end

end
