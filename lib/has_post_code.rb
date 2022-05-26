# Certain models have a location expressed as a UK post code:
# The following code is common to all of them

module HasPostCode
  def coordinates
    if post_code && post_area = PostArea.where(:subcode => post_code.split(' ').first).first
      [post_area.latitude, post_area.longitude]
    else
      [55, 0]
    end
  end

  def region_id_from_post_code
    post_code && PostRegion.find_by_subcode(post_code[/\A[A-Z]*/]).try(:region_id)
  end

  def self.included(cls)
    # do some normalization on post codes to make it more likely to pass validation
    cls.send(:before_validation) do |record|
      if record.post_code
        record.post_code.strip!
        record.post_code.gsub!(/\s+/, ' ')
        if record.post_code !~ / / && record.post_code =~ /\d[a-zA-Z]{2}\Z/
          record.post_code[-3...-3] = ' '
        end
        record.post_code.upcase!
      end
    end

    cls.send(:before_save) do |record|
      record.region_id = region_id_from_post_code if record.post_code_changed?
    end

    # validate that the post code has a subcode which we recognize
    cls.send(:validates_each, :post_code) do |record, attr, value|
      if record.post_code_changed? && value.present? && !PostArea.where(subcode: value.split(' ').first).exists?
        record.errors.add(:post_code, 'is invalid: there is no such postal area as "' + value.split(' ').first + '"')
      end
    end

    cls.send(:validates_format_of, :post_code, with: /\A[a-zA-Z][a-zA-Z0-9]{1,3} \d[a-zA-Z]{2}\z/, allow_nil: true)

    def cls.for_region_id(region_id)
      joins("JOIN post_regions ON post_regions.subcode = substring(#{self.table_name}.post_code from '^[A-Z]*')").joins("JOIN regions ON regions.id = post_regions.region_id").where('regions.id = ?', region_id.to_i)
    end
  end
end
