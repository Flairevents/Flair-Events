class NoAllowanceInShifts < ActiveRecord::Migration[5.1]
  def change
    # The Flair office staff want to manually set the 'allowance' for each
    #   employee in the Payroll view
    # They do not want us to automatically set the allowance based on how long
    #   each person works
    remove_column :shifts, :allowance
    remove_column :shifts, :min_hrs_for_allowance
  end
end
