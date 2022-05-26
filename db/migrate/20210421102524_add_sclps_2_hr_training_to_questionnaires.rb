class AddSclps2HrTrainingToQuestionnaires < ActiveRecord::Migration[5.2]
  def change
    add_column :questionnaires, :sclps_2_hr_training, :boolean, default: false
  end
end
