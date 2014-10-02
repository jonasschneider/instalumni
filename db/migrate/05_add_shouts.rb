class AddShouts < ActiveRecord::Migration
  def change
    create_table :shouts do |t|
      t.integer :author_id
      t.text :body

      t.timestamps
    end
  end
end
