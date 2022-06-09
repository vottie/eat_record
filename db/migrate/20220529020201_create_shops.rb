class CreateShops < ActiveRecord::Migration[7.0]
  def change
    create_table :shops do |t|
      t.string :name
      t.string :place
      t.string :address
      t.float :latitude
      t.string :longitude

      t.timestamps
    end
  end
end
