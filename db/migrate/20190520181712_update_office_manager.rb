class UpdateOfficeManager < ActiveRecord::Migration[5.2]
  def up
    rename_column :events, :office_manager, :office_manager_old
    add_reference :events, :office_manager, foreign_key: { to_table: :officers }
    Event.connection.schema_cache.clear!
    Event.reset_column_information

    #valid_managers = %w(Hannah Amanda Kerry Emma Elise Elise Emma Clare)
    ##### For now we are skipping over past managers, but late on we may need to instead recreate them in the office zone
    ##### so that we can reference them
    #past_managers = %w(Courtney Max Lauren Laura Penny Kez)

    db.execute "ALTER TABLE officers DROP CONSTRAINT officers_role_check"
    db.execute "ALTER TABLE officers ADD CHECK (role IN ('admin', 'manager', 'staffer', 'archived'))"

    okay_to_skip = %w(TBC X All Tbc)

    past_managers = [
      {first_name: 'Courtney', last_name: 'Wright'},
      {first_name: 'Max',      last_name: 'Bartholomew'},
      {first_name: 'Lauren',   last_name: 'McCahy'},
      {first_name: 'Penny',    last_name: 'Clark'},
      {first_name: 'Laura',    last_name: 'Paddock'}
    ]

    past_managers.each_with_index do |info, i|
      officer = Officer.where(first_name: info[:first_name], last_name: info[:last_name], role: 'archived', email: "oldofficer#{i}@flairevents.co.uk").first_or_create
      account = Account.where(user_type: 'Officer', user_id: officer.id, locked: true).first_or_create
    end

    unrecognized_officers = []

    Event.all.select {|e| e.office_manager_old}.each do |e|
      office_managers_old = []
      e.office_manager_old.strip.split(/[^A-Za-z ]/).each do |split_office_manager_old|
        office_manager_old = split_office_manager_old.titleize.gsub(/\s+.*$/, '')
        office_manager_old = 'Kerry' if office_manager_old == 'Kez'
        office_managers_old << office_manager_old
      end
      if (officer = Officer.find_by(first_name: office_managers_old[0]))
        e.office_manager_id = officer.id 
        e.notes += (e.notes ? e.notes + '\n' : '') + "Other Office Manager: #{office_managers_old[1]}" if (office_managers_old.length > 1)
        e.save!
      elsif okay_to_skip.include? office_managers_old[0]
        next
      else  
        unrecognized_officers << office_managers_old[0]
      end
    end

    raise "Unrecognized Officers: #{unrecognized_officers.uniq}" if unrecognized_officers.length > 0 

    remove_column :events, :office_manager_old
  end
  
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
