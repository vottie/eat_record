class CreateEatRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :eat_records do |t|
      t.string :shop_name
      t.string :place_name
      t.string :usecase
      t.string :eat_with
      t.date :eat_date
      t.string :eat_time
      t.string :eat_menu
      t.integer :eat_times

      t.timestamps
    end
  end
end
