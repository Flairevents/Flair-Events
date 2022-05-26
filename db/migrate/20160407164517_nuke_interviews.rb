class NukeInterviews < ActiveRecord::Migration
  def change
    Interview.destroy_all
    InterviewSlot.destroy_all
    InterviewBlock.destroy_all
    BulkInterview.destroy_all
  end
end
