class CreateOrders < ActiveRecord::Migration[7.1] 
  def change
    create_table :orders do |t|
      
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      
      t.decimal :total_price, precision: 10, scale: 2
      
      
      t.string :status, null: false, default: 'pending'
      t.timestamps
    end
    
    
  end
end
