class AddEyeline < ActiveRecord::Migration
  def change
    add_column :avatars, :eyeline, :float
  end
end
