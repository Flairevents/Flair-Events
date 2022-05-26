class CreateAccountsForClientContacts < ActiveRecord::Migration[5.2]
  def up
    db.execute "ALTER TABLE accounts DROP CONSTRAINT accounts_user_type_check" 
    db.execute "ALTER TABLE accounts ADD CONSTRAINT accounts_user_type_check  CHECK (((user_type)::text = ANY (ARRAY[('Prospect'::character varying)::text, ('Officer'::character varying)::text, ('ClientContact'::character varying)::text])))"
    ClientContact.all.each do |cc|
      Account.create(user_id: cc.id, user_type: 'ClientContact')
    end 
  end
  def down
    db.execute "ALTER TABLE accounts DROP CONSTRAINT accounts_user_type_check" 
    Account.where(user_type: 'ClientContact', user_id: ClientContact.all.pluck(:id)).destroy_all 
    db.execute "ALTER TABLE accounts ADD CONSTRAINT accounts_user_type_check  CHECK (((user_type)::text = ANY (ARRAY[('Prospect'::character varying)::text, ('Officer'::character varying)::text])))"
  end
end
