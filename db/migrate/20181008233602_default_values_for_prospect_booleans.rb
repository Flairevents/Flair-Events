class DefaultValuesForProspectBooleans < ActiveRecord::Migration[5.2]
  def change
    change_column_default :prospects, :prefers_morning,       false
    change_column_default :prospects, :prefers_afternoon,     false
    change_column_default :prospects, :prefers_early_evening, false
    change_column_default :prospects, :prefers_midweek,       false
    change_column_default :prospects, :prefers_weekend,       false

    pg.exec("UPDATE prospects SET prefers_morning       = false WHERE prefers_morning       IS NULL")
    pg.exec("UPDATE prospects SET prefers_afternoon     = false WHERE prefers_afternoon     IS NULL")
    pg.exec("UPDATE prospects SET prefers_early_evening = false WHERE prefers_early_evening IS NULL")
    pg.exec("UPDATE prospects SET prefers_midweek       = false WHERE prefers_midweek       IS NULL")
    pg.exec("UPDATE prospects SET prefers_weekend       = false WHERE prefers_weekend       IS NULL")

    change_column_null :prospects, :prefers_morning,       false
    change_column_null :prospects, :prefers_afternoon,     false
    change_column_null :prospects, :prefers_early_evening, false
    change_column_null :prospects, :prefers_midweek,       false
    change_column_null :prospects, :prefers_weekend,       false
  end
end
