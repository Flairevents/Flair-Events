class MigrateQuestionnaire < ActiveRecord::Migration
  def up
    Prospect.all.each do |prospect|
      answers = {}
      Answer.where(prospect_id: prospect.id).each do |answer|
        answers[answer.question_id] = answer.answer
      end
      if answers.length > 0
        questions = %w{has_customer_service_experience enjoys_working_outdoors enjoy_working_on_team interested_in_bar interested_in_marshal admin_experience retail_experience team_leader_experience promotions_experience data_collection_experience sales_experience different_and_fun last_magazine favorite_film best_place qualifications customer_service_experience related_experience describe_yourself past_employer_description heard_about_flair}
        questionnaire = Questionnaire.new(prospect_id: prospect.id)
        questions.each do |question|
          skip = false
          case question
            when 'qualifications'
              question_target = 'qualifications_general'
            else
              question_target = question
          end         
          questionnaire[question_target] = answers[question] unless skip
        end
        questionnaire.version = 1
        questionnaire.save
      end
    end
  end
  def down
    Questionnaire.destroy_all
  end
end
