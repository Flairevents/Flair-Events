class AddTaxCodesToTaxYear < ActiveRecord::Migration[5.2]
  def up
    add_column :tax_years, :tax_code_a, :string
    add_column :tax_years, :tax_code_b, :string
    add_column :tax_years, :tax_code_c, :string
    date = Date.new(2019, 05, 01)
    tax_year_2019 = TaxYear.where('date_start <= ? AND ? <= date_end', date, date).first
    tax_year_2019.tax_code_a = '1250L'
    tax_year_2019.tax_code_b = '1250L'
    tax_year_2019.tax_code_c = 'BR'
    tax_year_2019.save
    date = Date.new(2018, 05, 01)
    tax_year_2018 = TaxYear.where('date_start <= ? AND ? <= date_end', date, date).first
    tax_year_2018.tax_code_a = '1185L'
    tax_year_2018.tax_code_b = '1185L'
    tax_year_2018.tax_code_c = 'BR'
    tax_year_2018.save
  end
  def down
    remove_column :tax_years, :tax_code_a
    remove_column :tax_years, :tax_code_b
    remove_column :tax_years, :tax_code_c
  end
end
