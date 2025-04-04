# db/migrate/YYYYMMDDHHMMSS_create_order_line_items.rb
# Replace YYYYMMDDHHMMSS with the actual timestamp

# Defines the join table 'order_line_items' connecting orders
# to the specific part options selected for that order.
class CreateOrderLineItems < ActiveRecord::Migration[7.1] # Use your Rails version
  def change
    create_table :order_line_items do |t|
      # Foreign key to the orders table
      t.references :order, null: false, foreign_key: true, index: true
      # Foreign key to the part_options table
      t.references :part_option, null: false, foreign_key: true, index: true

      t.timestamps

      # Ensure a specific option cannot be added twice to the same order
      t.index [:order_id, :part_option_id], unique: true, name: 'index_order_line_items_on_order_and_option'
    end
  end
end
