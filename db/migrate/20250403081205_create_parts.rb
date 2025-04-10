class CreateParts < ActiveRecord::Migration[8.0]
  def change
    create_table :parts do |t|
      t.string :name
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
