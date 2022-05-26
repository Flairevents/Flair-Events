# A TextBlock is a site admin-editable block of text which can be used in an HTML page or e-mail template
# This is the basis of a primitive content-management capability

# The text is cached in memory
# The DB is used as a backup (for when the application server is restarted)

require 'office_zone_sync'

class TextBlock < ApplicationRecord
  include OfficeZoneSync

  # Need to change 'inheritance_column', because we are using a column called 'type'
  # Otherwise Rails will think the 'type' column has special significance
  self.inheritance_column = 'we_are_not_using_inheritance_here_stupid_orm'

  # We keep ALL "terms" text forever
  # So it is expected that multiple "terms" blocks may exist in the DB with the same key
  validates_uniqueness_of :key, scope: :type, unless: fn { |block| block.type == 'terms' }

  STATUSES = %w{DRAFT PUBLISHED}.freeze
  validates_inclusion_of :status, in: STATUSES

  #Save the date when the status is changed to published.
  def status=(value)
    write_attribute(:date_published, Date.today()) if status != 'PUBLISHED' && value == 'PUBLISHED'
    write_attribute(:status, value)
  end

  # Keep our in-memory cache up to date
  after_save do |block|
    newest = TextBlock.where(key: block.key, type: block.type).order('created_at DESC').first
    if block.id == newest.id
      Rails.cache.write("flair-textblock-#{block.key}-#{block.type}", block.contents)
    end
  end

  # Don't allow terms to be deleted or edited
  def delete
    raise "Can't delete terms" if self.type == 'terms'
    super
  end
  def destroy
    raise "Can't destroy terms" if self.type == 'terms'
    super
  end

  before_update do |block|
    raise "Can't modify previously stored terms" if block.type == 'terms'
  end

  def self.[](key)
    self.get(key, 'page')
  end

  # Retrieve the content which we have stored under a specific key
  def self.get(key,type)
    raise "Funny key"  if key.blank?
    raise "Funny type" if type.blank?

    # Caching needs work, so disabling for now. It seems that it is running an independent cache for each
    # rails instance, causing caches to be out of sync. Perhaps try MemCached in the future
    result = nil #Rails.cache.read("flair-textblock-#{key}-#{type}")

    if key == 'privacy_date'
      if result.nil? && block = TextBlock.where(key: 'privacy', type: type).order('created_at DESC').first
        result = block.date_published
        Rails.cache.write("flair-textblock-#{key}-#{type}", result)
      end
      result
    else
      if result.nil? && block = TextBlock.where(key: key, type: type).order('created_at DESC').first
        result = block.contents
        Rails.cache.write("flair-textblock-#{key}-#{type}", result)
      end
      (result || '').html_safe
    end
  end

  def self.keys
    pluck('DISTINCT key')
  end

  def thumbnail_url
    thumbnail ? '/content_thumbnails/'+thumbnail : ActionController::Base.helpers.image_path("news.png")
  end

  THUMBNAIL_SIZE = {width:100, height: 100}

end