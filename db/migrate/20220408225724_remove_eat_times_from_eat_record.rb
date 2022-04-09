class RemoveEatTimesFromEatRecord < ActiveRecord::Migration[7.0]
  def change
    remove_column :eat_records, :eat_times, :integer
  end
end
