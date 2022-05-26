class RemoveTypeCheckConstraintFromTextBlock < ActiveRecord::Migration
  def change
    execute 'ALTER TABLE "text_blocks" DROP CONSTRAINT "text_blocks_type_check";'
  end
end
