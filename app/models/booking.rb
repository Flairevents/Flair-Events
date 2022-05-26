require 'office_zone_sync'

class Booking < ApplicationRecord
  include OfficeZoneSync

  belongs_to :event_client
  belongs_to :client_contact, optional: true
  delegate :client, to: :event_client
  delegate :event, to: :event_client

  validates_presence_of :event_client_id

  after_initialize do |booking|
    booking.breaks = "20 mins every 6 hrs as per legal requirements." unless booking.breaks
    booking.food =  "None provided, staff to provide their own food. Client to supply drinking water." unless booking.food
    booking.transport = "None provided, staff to make their own way to site." unless booking.transport
    if self.event_client && self.client && self.client.name && self.client.accountant_email && !booking.invoicing
      booking.invoicing = "To be sent to #{self.client.accountant_email} on behalf of #{self.client.name}. Please inform us if any of these details are incorrect or if a P.O. number is required."
    end
  end
end