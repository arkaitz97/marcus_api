class CreatePriceRules < ActiveRecord::Migration[7.1]
  def change
    create_table :price_rules do |t|
      t.references :part_option_a, null: false, foreign_key: { to_table: :part_options }, index: true
      t.references :part_option_b, null: false, foreign_key: { to_table: :part_options }, index: true
      t.decimal :price_premium, precision: 10, scale: 2, null: false

      t.timestamps

      t.index [:part_option_a_id, :part_option_b_id], unique: true, name: 'index_price_rules_on_option_pair'
    end
  end
end
