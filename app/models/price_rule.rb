class PriceRule < ApplicationRecord
  belongs_to :part_option_a, class_name: 'PartOption'
  belongs_to :part_option_b, class_name: 'PartOption'
  validates :price_premium, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :options_must_be_different
  validate :inverse_rule_does_not_exist, on: :create
  private
  def options_must_be_different
    if part_option_a_id == part_option_b_id
      errors.add(:base, "A price rule cannot apply to the same part option twice.")
    end
  end
  def inverse_rule_does_not_exist
    if PriceRule.exists?(part_option_a_id: part_option_b_id, part_option_b_id: part_option_a_id)
      errors.add(:base, "The inverse price rule (swapping options A and B) already exists.")
    end
  end
end
