module PersonalDetailsHelper
  def ni_number_required_class
    'required' if @prospect.applicant?
  end
end