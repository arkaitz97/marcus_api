class PartRestriction < ApplicationRecord
  belongs_to :part_option, class_name: 'PartOption'
  belongs_to :restricted_part_option, class_name: 'PartOption'
  validate :options_must_be_different
  validate :inverse_restriction_does_not_exist, on: :create
  private
  def options_must_be_different
    if part_option_id == restricted_part_option_id
      errors.add(:base, "A part option cannot restrict itself.")
    end
  end
  def inverse_restriction_does_not_exist
    if PartRestriction.exists?(part_option_id: restricted_part_option_id, restricted_part_option_id: part_option_id)
      errors.add(:base, "The inverse restriction (where the restricted option restricts the primary option) already exists.")
    end
  end
end
