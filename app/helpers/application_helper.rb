require 'authentication'

module ApplicationHelper
  include Authentication::Accessors

  UK = Country.find_by_name('United Kingdom')
  OTHERS = Country.order(:name)

  def nationality_options
    [[''], ['United Kingdom', 108]].concat(OTHERS.map { |c| [c.name, c.id]})
  end

  def other_nationality_options
    OTHERS.map { |c| [c.name, c.id] unless main_groups_id.include?(c.id)}.compact
  end

  def get_id_by_name(name)
    Country.find_by_name(name).id
  end

  def main_groups_id
    Country.where(name: ['United Kingdom', 'Ireland']).pluck(:id)
  end

  # like content_for, but if used in a partial, and the partial is rendered
  #   more than once, it will only add the content once
  def content_once_for(name, key = caller[0], &block)
    @__content_once_map ||= {}
    @__content_once_map[name] ||= {}
    unless @__content_once_map[name].key? key
      content_for(name, &block)
      @__content_once_map[name][key] = true
    end
    nil
  end
  alias :content_for_once :content_once_for
end
