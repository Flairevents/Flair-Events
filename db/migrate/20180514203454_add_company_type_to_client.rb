class AddCompanyTypeToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :company_type, :string
  end
end
