class GetRidOfLimbo < ActiveRecord::Migration[5.1]
  def change
    Prospect.where(status: 'LIMBO').each do |prospect|
      prospect.status = 'EMPLOYEE'
      prospect.save!
    end
  end
end
