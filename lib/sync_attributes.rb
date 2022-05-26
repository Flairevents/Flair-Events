##### For any attributes that have a corresponding _updated_at column (ie. name and name_updated_at) this will:
#####  If *_updated_at is NOT being updated:
#####    - Update *_updated_at with the time of save
#####  If *_updated_at IS also being updated
#####    - Don't save the attribute if the existing *_updated_at is newer than the one to be saved

module SyncAttributes
  extend ActiveSupport::Concern

  ##### This module assumes that any attributes that would like to be synced by API have a corresponding attributes
  ##### attribute_updated_at (ie. name, name_updated_at)
  included do
    before_save :update_timestamps
  end

  def update_timestamps
    self.changed_attributes.each do |k,v|
      k_updated_at = (k.to_s+'_updated_at').to_sym
      if self.has_attribute?(k_updated_at)
        k_updated_at_was = (k_updated_at.to_s + '_was').to_sym
        # If the change being saved is older than what's already there, don't save it
        if self[k_updated_at] && self.send(k_updated_at_was) && (self[k_updated_at] < self.send(k_updated_at_was))
          self.clear_attribute_changes([k, k_updated_at])
        # Update the timestamp unless it is being saved directly
        elsif !(self.changed_attributes.keys.include? k_updated_at.to_s)
          self[k_updated_at] = DateTime.now
        end
      end
    end
  end
end