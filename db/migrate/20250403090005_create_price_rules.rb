# db/migrate/YYYYMMDDHHMMSS_create_price_rules.rb
# Replace YYYYMMDDHHMMSS with the actual timestamp

# Defines the 'price_rules' table to store price adjustments
# applied when specific pairs of part options are selected together.
class CreatePriceRules < ActiveRecord::Migration[7.1] # Use your Rails version
  def change
    create_table :price_rules do |t|
      # Foreign key for the first part option in the rule pair.
      t.references :part_option_a, null: false, foreign_key: { to_table: :part_options }, index: true
      # Foreign key for the second part option in the rule pair.
      t.references :part_option_b, null: false, foreign_key: { to_table: :part_options }, index: true
      # The price premium to add when both options A and B are selected.
      t.decimal :price_premium, precision: 10, scale: 2, null: false

      t.timestamps

      # Add a unique index on the pair of options (A, B).
      # Similar to restrictions, this prevents exact duplicates but doesn't
      # enforce symmetry (A, B vs B, A) alone. Symmetry handled in the model.
      t.index [:part_option_a_id, :part_option_b_id], unique: true, name: 'index_price_rules_on_option_pair'
    end
  end
end
