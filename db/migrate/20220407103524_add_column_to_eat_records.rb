class AddColumnToEatRecords < ActiveRecord::Migration[7.0]
  def change
    add_reference :eat_records, :user, foreign_key: true
  end
end
