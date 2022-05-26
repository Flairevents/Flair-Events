class RemoveOriginalIdSighted < ActiveRecord::Migration[5.2]
  def change
    # this column on prospects is not used for anything
    remove_column :prospects, :original_id_sighted
  end
end
