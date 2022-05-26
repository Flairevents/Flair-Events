class UpdateAccomodationFields < ActiveRecord::Migration[5.1]
  def change
    remove_column :events, :accom_confirmation,        :boolean, null: false, default: false
    remove_column :events, :accom_parking,             :boolean, null: false, default: false 
    remove_column :events, :accom_required,            :string
    remove_column :events, :accom_paid,                :boolean, null: false, default: false
    remove_column :events, :accom_num_rooms,           :string
    remove_column :events, :accom_num_beds,            :string
    remove_column :events, :accom_booking_date,        :date
    add_column    :events, :accom_room_info,           :text
    add_column    :events, :accom_distance,            :text
    add_column    :events, :accom_booking_dates,       :text
    add_column    :events, :accom_parking,             :text
    add_column    :events, :accom_wifi,                :text
    add_column    :events, :accom_cancellation_policy, :text
    add_column    :events, :accom_payment_method,      :text
    add_column    :events, :accom_booked_by,           :text
  end
end
