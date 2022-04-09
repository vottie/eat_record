class AddColumnToEatRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :eat_records, :article, :string
  end
end
