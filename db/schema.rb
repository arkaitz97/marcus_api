# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_04_154126) do
  create_table "order_line_items", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "part_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_line_items_on_order_id"
    t.index ["part_option_id"], name: "index_order_line_items_on_part_option_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "customer_name", null: false
    t.string "customer_email", null: false
    t.decimal "total_price", precision: 10, scale: 2
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "part_options", force: :cascade do |t|
    t.string "name"
    t.decimal "price", precision: 10, scale: 2
    t.integer "part_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_part_options_on_part_id"
  end

  create_table "part_restrictions", force: :cascade do |t|
    t.integer "part_option_id", null: false
    t.integer "restricted_part_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_option_id", "restricted_part_option_id"], name: "index_part_restrictions_on_option_pair", unique: true
    t.index ["part_option_id"], name: "index_part_restrictions_on_part_option_id"
    t.index ["restricted_part_option_id"], name: "index_part_restrictions_on_restricted_part_option_id"
  end

  create_table "parts", force: :cascade do |t|
    t.string "name"
    t.integer "product_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_parts_on_product_id"
  end

  create_table "price_rules", force: :cascade do |t|
    t.integer "part_option_a_id", null: false
    t.integer "part_option_b_id", null: false
    t.decimal "price_premium", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_option_a_id", "part_option_b_id"], name: "index_price_rules_on_option_pair", unique: true
    t.index ["part_option_a_id"], name: "index_price_rules_on_part_option_a_id"
    t.index ["part_option_b_id"], name: "index_price_rules_on_part_option_b_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "order_line_items", "orders"
  add_foreign_key "order_line_items", "part_options"
  add_foreign_key "part_options", "parts"
  add_foreign_key "part_restrictions", "part_options"
  add_foreign_key "part_restrictions", "part_options", column: "restricted_part_option_id"
  add_foreign_key "parts", "products"
  add_foreign_key "price_rules", "part_options", column: "part_option_a_id"
  add_foreign_key "price_rules", "part_options", column: "part_option_b_id"
end
