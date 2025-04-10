class CreateOrders < ActiveRecord::Migration[7.1] # Use your Rails version
  def change
    create_table :orders do |t|
      # Customer details
      t.string :customer_name, null: false
      t.string :customer_email, null: false

      # Calculated total price for the order
      t.decimal :total_price, precision: 10, scale: 2

      # Order status (e.g., pending, processing, completed, cancelled)
      # Add null: false and a default value. Index is added by the generator.
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
    # Add index on email if frequent lookups by email are expected
    # add_index :orders, :customer_email
  end
end
