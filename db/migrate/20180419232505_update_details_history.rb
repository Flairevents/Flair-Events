class UpdateDetailsHistory < ActiveRecord::Migration[5.1]
  def up
    add_column :details_history, :column, :string
    add_column :details_history, :prev_value, :string
    add_column :details_history, :new_value, :string
    add_column :details_history, :changed_by, :string

    puts("Deleting History for prospects that no longer exist")
    DetailsHistory.all.each do |dh|
      dh.destroy unless Prospect.find_by_id(dh.prospect_id) 
    end

    prospect_ids = DetailsHistory.pluck(:prospect_id).uniq

    puts("Porting Details History")
    prospect_ids.each do |prospect_id|
      prospect = Prospect.find(prospect_id)
      detail_histories = DetailsHistory.where(prospect_id: prospect.id) 
      DetailsHistory.tracked_columns.each do |column|
        if dhs = detail_histories.where("#{column} IS NOT NULL").sort_by {|r| r.created_at }
          for i in 0..(dhs.length-1)
            prev_val = dhs[i][column]
            next_val = (i == (dhs.length-1)) ? prospect[column] : dhs[i+1][column]
            # Create history if: values are different, at least one is not blank, and the first entry is not blank
            if prev_val != next_val && !(prev_val.blank? && next_val.blank?) && !(prev_val.blank? && i==0)
              new_dh = DetailsHistory.new( 
                prospect_id: prospect.id,
                column: column,
                prev_value: prev_val,
                new_value: next_val,
                created_at: dhs[i].created_at,
                changed_by: dhs[i].description.gsub('Edited by ', '').gsub('Change Request, approved by ', ''))
              new_dh.save!
            end
          end
        end
      end
    end

    puts("Deleting old Details History")
    DetailsHistory.where(column: nil).destroy_all

    remove_column :details_history, :description 
    remove_column :details_history, :first_name
    remove_column :details_history, :last_name
    remove_column :details_history, :date_of_birth
    remove_column :details_history, :gender
    remove_column :details_history, :nationality_id
    remove_column :details_history, :address
    remove_column :details_history, :address2
    remove_column :details_history, :city
    remove_column :details_history, :post_code
    remove_column :details_history, :email
    remove_column :details_history, :home_no
    remove_column :details_history, :mobile_no
    remove_column :details_history, :emergency_no
    remove_column :details_history, :emergency_name
    remove_column :details_history, :ni_number
    remove_column :details_history, :tax_choice
    remove_column :details_history, :student_loan
    remove_column :details_history, :bank_sort_code
    remove_column :details_history, :bank_account_no
    remove_column :details_history, :bank_account_name
    remove_column :details_history, :id_type
    remove_column :details_history, :id_number
    remove_column :details_history, :visa_number
    remove_column :details_history, :visa_expiry
  end
end
