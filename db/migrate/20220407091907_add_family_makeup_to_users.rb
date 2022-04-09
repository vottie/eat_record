class AddFamilyMakeupToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :family_makeup, :string
  end
end
