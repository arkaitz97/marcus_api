class PartOption < ApplicationRecord
  belongs_to :part
  has_many :restrictions, class_name: 'PartRestriction', foreign_key: 'part_option_id', dependent: :destroy, inverse_of: :part_option
  has_many :restricted_options, through: :restrictions, source: :restricted_part_option
  has_many :restricted_by, class_name: 'PartRestriction', foreign_key: 'restricted_part_option_id', dependent: :destroy, inverse_of: :restricted_part_option
  has_many :restricting_options, through: :restricted_by, source: :part_option

  has_many :price_rules_as_a,
           class_name: 'PriceRule',
           foreign_key: 'part_option_a_id',
           dependent: :destroy,
           inverse_of: :part_option_a

  has_many :price_rules_as_b,
           class_name: 'PriceRule',
           foreign_key: 'part_option_b_id',
           dependent: :destroy,
           inverse_of: :part_option_b

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def all_price_rules
    PriceRule.where("part_option_a_id = :id OR part_option_b_id = :id", id: self.id)
  end
end
