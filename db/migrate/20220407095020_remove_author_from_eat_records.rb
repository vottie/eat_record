class RemoveAuthorFromEatRecords < ActiveRecord::Migration[7.0]
  def change
    remove_column :eat_records, :author
  end
end
