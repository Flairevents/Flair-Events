class RejectEvent < ApplicationRecord
	belongs_to :prospect
	belongs_to :event
	belongs_to :job
end
