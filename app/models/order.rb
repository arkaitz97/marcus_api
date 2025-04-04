class Order < ApplicationRecord
    # --- Associations ---
    # An order consists of multiple line items, each linking to a selected part option.
    has_many :order_line_items, dependent: :destroy
    # Provides direct access to the PartOption records selected for this order.
    has_many :selected_part_options, through: :order_line_items, source: :part_option
  
    # --- Validations ---
    validates :customer_name, presence: true
    validates :customer_email, presence: true # Add format validation for production
    validates :status, presence: true, inclusion: { in: %w[pending processing completed cancelled],
                                                    message: "%{value} is not a valid status" }
    # total_price might be set by calculation logic, so presence validation might depend on workflow.
  
    # --- Constants ---
    VALID_STATUSES = %w[pending processing completed cancelled].freeze
  end
  