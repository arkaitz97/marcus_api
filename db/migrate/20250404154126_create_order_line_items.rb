class CreateOrderLineItems < ActiveRecord::Migration[7.1] 
  def change
    create_table :order_line_items do |t|
      
      t.references :order, null: false, foreign_key: true, index: true
      
      t.references :part_option, null: false, foreign_key: true, index: true
      t.timestamps
      
      t.index [:order_id, :part_option_id], unique: true, name: 'index_order_line_items_on_order_and_option'
    end
  end
end
