class AddIdSubmittedDateToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :id_submitted_date, :datetime, default: nil
  end
end
