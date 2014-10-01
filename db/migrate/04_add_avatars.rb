class AddAvatars < ActiveRecord::Migration
  def change
    add_column :users, :avatar_id, :integer

    create_table :avatars do |t|
      t.binary :image
      t.binary :ugly_image

      t.timestamps
    end
  end
end
