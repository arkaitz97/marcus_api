# app/models/part_option.rb
class PartOption < ApplicationRecord
  belongs_to :part

  # --- Associations for Restrictions ---

  # Restrictions where this part_option is the primary one (it restricts others)
  has_many :restrictions,
           class_name: 'PartRestriction',
           foreign_key: 'part_option_id',
           dependent: :destroy,
           inverse_of: :part_option

  # The actual PartOption records that this option restricts
  has_many :restricted_options,
           through: :restrictions,
           source: :restricted_part_option

  # Restrictions where this part_option is the restricted one (it is restricted by others)
  has_many :restricted_by,
           class_name: 'PartRestriction',
           foreign_key: 'restricted_part_option_id',
           dependent: :destroy,
           inverse_of: :restricted_part_option

  # The actual PartOption records that restrict this option
  has_many :restricting_options,
           through: :restricted_by,
           source: :part_option

  # --- Associations for Price Rules (Add these later) ---
  # has_many :price_rules_as_a, class_name: 'PriceRule', foreign_key: 'part_option_a_id', dependent: :destroy
  # has_many :price_rules_as_b, class_name: 'PriceRule', foreign_key: 'part_option_b_id', dependent: :destroy


  # --- Validations ---
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
