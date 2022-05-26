class AddFlagPhotoIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :flag_photo, :text


    prospect_ids = ActionTaken.all.distinct.pluck(:prospect_id)
    prospect_ids.each do |prospect_id|
      prospect = Prospect.find(prospect_id)
      action_taken = prospect.action_takens.order(:id).last
      prospect.flag_photo = if action_taken.reason == 'No Show'
                              "<div > <img class='name-column-flag' src='/flag_photo/red' > </div>"
                            elsif action_taken.reason == 'Cancelled Within 18 Hours of the Event'
                              "<div > <img class='name-column-flag' src='/flag_photo/amber' width='24px' height='24px'> </div>"
                            else
                              nil
                            end
      prospect.save
    end
  end
end
