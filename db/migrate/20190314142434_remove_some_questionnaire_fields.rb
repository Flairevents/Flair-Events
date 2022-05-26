class RemoveSomeQuestionnaireFields < ActiveRecord::Migration[5.2]
  def change
    remove_column :questionnaires, :university_town, :string
    remove_column :questionnaires, :university_postal_code, :string
    remove_column :questionnaires, :related_experience, :string
    remove_column :questionnaires, :has_customer_service_experience, :boolean
    remove_column :questionnaires, :enjoys_working_outdoors, :boolean
    remove_column :questionnaires, :admin_experience, :boolean
    remove_column :questionnaires, :data_collection_experience, :boolean
    remove_column :questionnaires, :sales_experience, :boolean
    remove_column :questionnaires, :different_and_fun, :boolean
  end
end
