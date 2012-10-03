class AddPublicAddressToUsers < ActiveRecord::Migration
  def change
    add_column :users, :public_address, :boolean, default: false
  end
end