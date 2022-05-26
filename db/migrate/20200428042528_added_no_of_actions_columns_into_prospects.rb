class AddedNoOfActionsColumnsIntoProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :completed_contracts, :integer
    add_column :prospects, :cancelled_contracts, :integer
    add_column :prospects, :cancelled_eighteen_hrs_contracts, :integer
    add_column :prospects, :no_show_contracts, :integer
    add_column :prospects, :non_confirmed_contracts, :integer
    add_column :prospects, :held_spare_contracts, :integer

    prospects = Prospect.where(id: ActionTaken.all.distinct.pluck(:prospect_id))
    prospects.each do |prospect|
      action_logs = ActionTaken.where(prospect_id: prospect.id)
      cancelled_contracts = action_logs.where(reason: 'Cancelled').count
      cancelled_eighteen_hrs_contracts = action_logs.where(reason: 'Cancelled Within 18 Hours of the Event').count
      no_show_contracts = action_logs.where(reason: 'No Show').count
      non_confirmed_contract_interests = action_logs.where(reason: 'No Confirmation of Interest').count
      non_confirmed_contract_gentles = action_logs.where(reason: 'No Confirmation - Gentle').count
      non_confirmed_contracts = non_confirmed_contract_interests + non_confirmed_contract_gentles
      held_spare_contracts = GigRequest.where(prospect_id: prospect.id, spare: true).count
      prospect.cancelled_contracts = cancelled_contracts if cancelled_contracts > 0
      prospect.cancelled_eighteen_hrs_contracts = cancelled_eighteen_hrs_contracts if cancelled_eighteen_hrs_contracts > 0
      prospect.no_show_contracts = no_show_contracts if no_show_contracts > 0
      prospect.non_confirmed_contracts = non_confirmed_contracts if non_confirmed_contracts > 0
      prospect.held_spare_contracts = held_spare_contracts if held_spare_contracts > 0
      prospect.save
    end
    Event.where(status: 'FINISHED').each do |event|
      prospects = Prospect.where(id: event.gigs.distinct.pluck(:prospect_id))
      prospects.each do |prospect|
        if prospect.completed_contracts.nil?
          prospect.completed_contracts = 1
        else
          prospect.completed_contracts = prospect.completed_contracts + 1
        end
        prospect.save
      end
    end
  end
end
