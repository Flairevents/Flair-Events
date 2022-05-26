##### Temporarily keep track of any records that were created/updated/deleted.
##### We will then send these to the office zone and delete the local data
##### Include this in any model you want to keep synced with the office zone
##### If a record can have a preliminary state where it is not yet ready to sync,
#####   add a 'okay_to_sync' method to it that returns a boolean indicating whether
#####   the object is ready to export or not

require 'user_info'
require 'models/export'

module OfficeZoneSync
  include UserInfo
  include Models::Export
  extend ActiveSupport::Concern
  included do
    after_commit :sync_create_or_update, on: [:create, :update]
    after_commit :sync_deletion, on: [:destroy]
    after_validation :cache_errors
    after_rollback :cache_errors
  end

  def sync_create_or_update
    if previous_changes.any?
      reload #Reload from database after save to get any changes from db normalization
      if UserInfo.controller_name == 'office' && (!defined?(self.okay_to_sync) || self.okay_to_sync)
        RequestStore.store[:office_zone_sync] ||= {}
        RequestStore.store[:office_zone_sync][:updated] ||= {}
        RequestStore.store[:office_zone_sync][:updated][self.class.table_name.to_s] ||= {}
        export_method = 'export_' + self.class.name.downcase.to_s.gsub('_', '') + '_object(self)'
        ###### Export new/updated object to hash. Use ID as key to overwrite any (older) duplicates
        RequestStore.store[:office_zone_sync][:updated][self.class.table_name.to_s][self.id] = eval(export_method)
      end
    end
  end

  def sync_deletion
    # Create Deletion Record so that other Office Zone instances can update their db cache when they sync
    Deletion.create!(table: self.class.table_name, record_id: self.id)
    if UserInfo.controller_name == 'office'
      RequestStore.store[:office_zone_sync] ||= {}
      RequestStore.store[:office_zone_sync][:deleted] ||= {}
      # Also record the ID, which will be returned immediately
      RequestStore.store[:office_zone_sync][:deleted][self.class.table_name.to_s] ||= []
      RequestStore.store[:office_zone_sync][:deleted][self.class.table_name.to_s] << self.id
      # Clear any create/update syncs that may exist
      if RequestStore.store[:office_zone_sync][:updated]
        if RequestStore.store[:office_zone_sync][:updated][self.class.table_name.to_s]
          RequestStore.store[:office_zone_sync][:updated][self.class.table_name.to_s].delete(self.id)
        end
      end
    end
  end

  def cache_errors
    if UserInfo.controller_name == 'office'
      RequestStore.store[:office_zone_sync] ||= {}
      if errors.full_messages.length > 0
        RequestStore.store[:office_zone_sync][:error_messages] ||= []
        error_messages = []
        RequestStore.store[:office_zone_sync][:error_messages].concat(errors.full_messages.map {|m| respond_to?(:prepend_error_message) ? prepend_error_message + m : m})
      end
    end
  end

  def self.reject_deleted(activeRecordClass, ids)
    isArray = true
    unless ids.class == Array
      ids = [ids]
      isArray = false
    end

    new_ids, deleted_ids = ids.partition { |id| activeRecordClass.exists? id }

    deleted_ids.each do |id|
      RequestStore.store[:office_zone_sync] ||= {}
      RequestStore.store[:office_zone_sync][:deleted] ||= {}
      RequestStore.store[:office_zone_sync][:deleted][activeRecordClass.table_name.to_s] ||= []
      RequestStore.store[:office_zone_sync][:deleted][activeRecordClass.table_name.to_s] << id
    end
    isArray ? new_ids : new_ids[0]
  end

  def self.get_synced_response(data={})
    data ||= {}
    new_data = {}
    RequestStore.store[:office_zone_sync] ||= {}

    if RequestStore.store[:office_zone_sync][:updated]
      new_data[:tables] = {}
      RequestStore.store[:office_zone_sync][:updated].each do |table_name, objects|
        new_data[:tables][table_name] = objects.values
      end
      RequestStore.store[:office_zone_sync].delete(:updated)
    end

    if RequestStore.store[:office_zone_sync][:deleted]
      new_data[:deleted] = RequestStore.store[:office_zone_sync][:deleted].clone
      RequestStore.store[:office_zone_sync].delete(:deleted)
    end

    if RequestStore.store[:office_zone_sync][:error_messages]
      new_data[:status] = 'error'
      new_data[:message] = RequestStore.store[:office_zone_sync][:error_messages].uniq.join("<br/>").html_safe
      RequestStore.store[:office_zone_sync].delete(:error_messages)
    else
      new_data[:status] = 'ok' unless data[:status] == 'error'
    end

    if data[:message] && new_data[:message]
      data[:message] = [data[:message], new_data[:message]].to_sentence
      new_data.delete(:message)
    end

    data = data.deep_merge(new_data) unless new_data.blank?
    data
  end
end
