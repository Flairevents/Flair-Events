class AddCovidColumnsToProspects < ActiveRecord::Migration[5.2]
  def change
    add_column :prospects, :has_c19_test, :boolean, default: false
    add_column :prospects, :test_site_code, :string
    add_column :prospects, :c19_tt_at, :datetime
    add_column :prospects, :is_clean, :boolean, default: false
    add_column :prospects, :is_convicted, :boolean, default: false
  end
end
