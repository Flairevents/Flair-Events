require 'office_zone_sync'

class LibraryItem < ApplicationRecord
  include OfficeZoneSync

  validates_presence_of :name, :filename
  validates_uniqueness_of :name, :filename
end