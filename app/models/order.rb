class Order < ApplicationRecord
    has_many :order_line_items, dependent: :destroy
    has_many :selected_part_options, through: :order_line_items, source: :part_option
  
    validates :customer_name, presence: true
    validates :customer_email, presence: true 
    validates :status, presence: true, inclusion: { in: %w[pending processing completed cancelled],
                                                    message: "%{value} is not a valid status" }
  
    VALID_STATUSES = %w[pending processing completed cancelled].freeze
  end
  