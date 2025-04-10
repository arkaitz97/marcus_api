class AddInStockToPartOptions < ActiveRecord::Migration[7.1] # Adjust version if needed
  def change
    add_column :part_options, :in_stock, :boolean, default: true, null: false
  end
end