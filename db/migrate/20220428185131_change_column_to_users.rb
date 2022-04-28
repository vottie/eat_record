class ChangeColumnToUsers < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :username, :string, null:false
    remove_column :users, :place, :string
    remove_column :users, :family_makeup, :string
  end
end
