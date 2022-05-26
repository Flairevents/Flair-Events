class ChangeIdTypeToShareCode < ActiveRecord::Migration[5.2]
  def change
    roi_id = Country.find_by(name: 'Ireland').id
    Prospect.where(nationality_id: roi_id).update_all(id_type: 'UK Passport')
  end
end
