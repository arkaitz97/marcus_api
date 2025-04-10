class OrderLineItem < ApplicationRecord
  belongs_to :order
  belongs_to :part_option
  validates :part_option_id, uniqueness: { scope: :order_id, message: "has already been added to this order" }
end
