require 'authentication'

module OfficeHelper
  include Authentication::Accessors

  def slideover_form(html_class, render_hash)
    "<div class='slideover #{html_class}' style='display:none; left:100%'>
      <a class='cancel'>Cancel</a>
      <a class='close'>X</a>
      <a class='save'><img src='#{image_path('little-disk.png')}' alt='Save'></a>
      <div class='slideover-content'>
        #{capture { render(render_hash) }}
      </div>
     </div>".html_safe
  end

  UK = Country.find_by_name('United Kingdom')
  OTHERS = Country.where("name <> 'United Kingdom'").order(:name)

  def prospectStatus
    ["SLEEPER", "IGNORED", "DEACTIVATED", "HAS_BEEN", "APPLICANT"]
  end

  def office_nationality_options
    [['', ''], ['United Kingdom', UK.id]].concat(OTHERS.map { |c| [c.name, c.id]})
  end

  # form helpers which don't add (duplicated) HTML IDs

  def _text_field(name, options={})
    "<input type='text' name='#{name}' #{options.map { |k,v| "#{k}='#{v}'" }.join(' ')} />".html_safe
  end

  def _text_area(name, options={})
    "<textarea name='#{name}' #{options.map { |k,v| "#{k}='#{v}'" }.join(' ')}></textarea>".html_safe
  end

  def _check_box(name, value, options={})
    "<input type='checkbox' name='#{name}' value='#{value}' #{options.map { |k,v| "#{k}='#{v}'" }.join(' ')} />".html_safe
  end

  def _select(name, option_tags='', options={})
    "<select name='#{name}' #{options.map { |k,v| "#{k}='#{v}'" }.join(' ')}>#{option_tags}</select>".html_safe
  end
end
