class ClearDefaultDatesOnQuestionnaire < ActiveRecord::Migration
  def change
    default_date = Date.civil(1986, 1, 1)
    Questionnaire.all.each do |q|
      q.job1_date_start = nil  if q.job1_date_start == default_date
      q.job1_date_finish = nil if q.job1_date_finish == default_date
      q.job2_date_start = nil  if q.job2_date_start == default_date
      q.job2_date_finish = nil if q.job2_date_finish == default_date
      q.save if q.changed?
    end
  end
end
