class NewQuestionnaire < ActiveRecord::Migration
  def up
    create_table :questionnaires do |t|
      t.integer :prospect_id, null: false
      # Work Experience
      ## Job 1
      t.date    :job1_date_start
      t.date    :job1_date_finish
      t.string  :job1_type
      t.string  :job1_position
      t.string  :job1_company
      t.text    :job1_description 
      ## Job 2
      t.date    :job2_date_start
      t.date    :job2_date_finish
      t.string  :job2_type
      t.string  :job2_position
      t.string  :job2_company
      t.text    :job2_description
      # Referee
      t.string  :referee_name
      t.string  :referee_position
      t.string  :referee_company
      t.string  :referee_phone
      t.string  :referee_email
      #Qualifications
      t.text    :qualifications_general
      t.string  :university_town
      t.string  :university_postal_code
      t.text    :qualifications_industry
      #Customer Service Experience
      t.text    :customer_service_experience
      t.text    :customer_service_why_interested
      t.text    :customer_service_meaning
      t.text    :ethics_meaning
      t.text    :related_experience
      # Abilities
      t.boolean :has_customer_service_experience
      t.boolean :enjoys_working_outdoors
      t.boolean :enjoy_working_on_team
      t.boolean :interested_in_bar
      t.boolean :interested_in_marshal
      t.boolean :admin_experience
      t.boolean :retail_experience
      t.boolean :team_leader_experience
      t.boolean :promotions_experience
      t.boolean :data_collection_experience
      t.boolean :sales_experience
      t.boolean :different_and_fun
      t.text    :other_attributes
      t.boolean :access_to_car
      # Short Questions
      t.string  :last_magazine
      t.string  :favorite_film
      t.string  :best_place
      t.string  :describe_yourself
      t.string  :past_employer_description
      t.string  :heard_about_flair
      # Criminal Conviction
      t.boolean :has_criminal_convictions
      t.text    :criminal_conviction_details
      t.timestamps
      # Legacy (track if this was ported from previous answers
      t.integer :version
    end
    add_index :questionnaires, :prospect_id
  end
  def down
    drop_table :questionnaires
  end
end
