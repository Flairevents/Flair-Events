class UpdateInterviewSlotsInterviewCount < ActiveRecord::Migration[5.2]
  def change
    InterviewSlot.all.each { |is| is.update_interview_counts }
  end
end
