class SetFullnessAndShowInPublicOnEvent < ActiveRecord::Migration
  def change
    Event.all.each do |e|
      if e.status == 'FULL' || e.status == 'HIDDEN'
        if e.status == 'FULL'
          puts("Setting #{e.name} Fullness to 'FULL'")
          e.fullness = 'FULL'
        end
        if e.status == 'HIDDEN'
          puts("Setting #{e.name} Show in Public to False")
          e.show_in_public = false
        end
        e.status = 'OPEN'
        e.save!
      end
    end
  end
end
