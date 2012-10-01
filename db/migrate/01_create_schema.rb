class CreateSchema < ActiveRecord::Migration
  def up
    create_table :users, primary_key: 'uid' do |t|
      t.string :uid

      t.string :name
      t.string :original_name

      t.string :address
      t.string :zip_city
      t.string :country

      t.string :phone
      t.string :email

      t.string :custom1_name
      t.string :custom1_value
      t.string :custom2_name
      t.string :custom2_value

      t.string :meta_meister
      t.string :meta_zukunft
      t.string :meta_nachabi
      t.string :meta_lebenswichtig
      t.string :meta_nachruf
      
      t.text :json_tags

      t.timestamps
    end

    create_table :posts do |t|
      t.string :user_uid
      t.text :body

      t.timestamps
    end
  end
 
  def down
    drop_table :users
    drop_table :posts
  end
end