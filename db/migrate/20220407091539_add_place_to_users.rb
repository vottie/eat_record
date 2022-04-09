class AddPlaceToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :place, :string
  end
end
