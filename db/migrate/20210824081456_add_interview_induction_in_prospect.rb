class AddInterviewInductionInProspect < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :interview_induction, :boolean, default: false
  end
end
