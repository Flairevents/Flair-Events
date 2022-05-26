require 'date'

module Flair::Test::Browser::Forms
  def def_form_input_methods(prefix, form, object, fields)
    fields.each do |field|
      class_eval <<-CODE
        def #{prefix}_#{field}_input
          @#{prefix}_#{field}_input ||= #{form}.find(':not([type="hidden"])[name="#{object}[#{field}]"]', visible: false)
        end
      CODE
    end
  end
end

module Flair::Test::Browser::OfficeZone
  def login_to_office_zone(email, password)
    visit 'http://localhost:3000/office/login'
    fill_in('login_email', with: email)
    fill_in('login_password', with: password)
    click_button('Login')
    # confirm that browser redirects to expected page
    current_path.must =~ /\/office$/
  end

  def login_to_office_zone_as_manager
    login_to_office_zone('manager@blah.com', 'abc')
  end

  def tabs
    @tabs ||= find('#view-tabs')
  end

  def datepicker
    # don't cache in ivar, as this is created/destroyed each time datepicker opened/closed
    find('.datepicker')
  end

  %w{home events gigs team applicants todos payroll bulkInterviews clients invoices content faq library office}.each do |tab_id|
    class_eval <<-CODE
      def #{tab_id}_pane
        @main_viewport  ||= find('#main-viewport')
        @#{tab_id}_pane ||= @main_viewport.find('##{tab_id}')
      end
    CODE
  end

  # If the element we are looking for is not present or not visible, run the block
  #   to make it appear
  def if_not_visible(parent, *selector)
    element = Capybara.using_wait_time(0) { parent.find(*selector) } rescue nil
    if !element
      yield
      element = parent.find(*selector)
    elsif !element.visible?
      yield
    end
    element.must.be_visible
    element
  end
end

# custom extensions to Sequel
class Sequel::Dataset
  def insert_with_tstamps(hash)
    insert(hash.merge(updated_at: Time.now.utc, created_at: Time.now.utc))
  end
end
