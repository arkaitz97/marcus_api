class CreatePartRestrictions < ActiveRecord::Migration[7.1] 
  def change
    create_table :part_restrictions do |t|
      t.references :part_option, null: false, foreign_key: { to_table: :part_options }, index: true
      t.references :restricted_part_option, null: false, foreign_key: { to_table: :part_options }, index: true
      t.timestamps
      t.index [:part_option_id, :restricted_part_option_id], unique: true, name: 'index_part_restrictions_on_option_pair'
    end
  end
end
