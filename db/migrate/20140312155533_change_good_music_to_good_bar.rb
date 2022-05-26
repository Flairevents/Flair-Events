class ChangeGoodMusicToGoodBar < ActiveRecord::Migration
  def up
    db.execute "ALTER TABLE prospects RENAME good_music TO good_bar"
  end

  def down
    db.execute "ALTER TABLE prospects RENAME good_bar TO good_music"
  end
end
