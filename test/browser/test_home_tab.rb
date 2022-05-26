class TestHomeTab < Flair::Test::Browser::Suite
  include Flair::Test::Browser::OfficeZone

  start_by 'log into Office Zone' do
    login_to_office_zone_as_manager
  end

  _then 'check Zone Summary looks OK (it should be empty right now)' do
    zone_summary = find('.zone_summary')
    zone_summary.must.be_visible
    zone_summary.text.must == "Employees Requests Spare Applicants No ID No TC No Bank No NI Change Requests Uploaded IDs\n0 0 0 0 0 0 0 0 0 0"
  end

  _then 'check tabs are displayed' do
    tabs.must.be_visible
    tabs.text.must == "Home\nEvents\nGigs\nTeam\nApplicants\nTo-Do\nPayroll\nInterviews\nClients\nInvoices\nContent\nFAQ\nLibrary\nOffice"
  end

  _then 'check Home tab is selected by default' do
    active_tab = tabs.find('.active')
    active_tab.tag_name.must == 'li'
    active_tab.text.must == 'Home'
  end
end
