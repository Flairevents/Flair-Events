class RenameGoodCorporateToGoodHospitalityInProspect < ActiveRecord::Migration
  def change
    rename_column :prospects, :good_corporate, :good_hospitality
  end
end
