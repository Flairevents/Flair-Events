class BlurbsNotNull < ActiveRecord::Migration[5.2]
  def change
    # All of these columns have default values, so there is no need for them to
    #   ever be NULL
    # (Though they can hold blank strings)

    change_column_null :events, :blurb_title,           false
    change_column_null :events, :blurb_subtitle,        false
    change_column_null :events, :blurb_opening,         false
    change_column_null :events, :blurb_closing,         false
    change_column_null :events, :blurb_job,             false
    change_column_null :events, :blurb_shift,           false
    change_column_null :events, :blurb_wage_additional, false
    change_column_null :events, :blurb_uniform,         false
    change_column_null :events, :blurb_transport,       false
  end
end
