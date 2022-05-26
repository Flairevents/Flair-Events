class ChangeOpeningSoonToRegisterInterest < ActiveRecord::Migration[5.2]
  def change
    Event.where(fullness: 'OPENING_SOON').update_all(fullness: 'REGISTER_INTEREST')
  end
end
