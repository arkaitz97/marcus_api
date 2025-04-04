# app/models/order_line_item.rb

# Join model connecting an Order to a selected PartOption.
class OrderLineItem < ApplicationRecord
  # --- Associations ---
  belongs_to :order
  belongs_to :part_option

  # --- Validations ---
  # Ensure the combination of order and part_option is unique.
  # This is also enforced by the database index, but model validation gives better errors.
  validates :part_option_id, uniqueness: { scope: :order_id, message: "has already been added to this order" }
end
