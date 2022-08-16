class AddPostCodeToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :postcode, :string
  end
end
