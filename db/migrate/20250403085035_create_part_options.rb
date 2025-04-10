class CreatePartOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :part_options do |t|
      t.string :name
      t.decimal :price, precision: 10, scale: 2
      t.references :part, null: false, foreign_key: true, index: true
      t.timestamps
    end
  end
end
