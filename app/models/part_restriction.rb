# app/models/part_restriction.rb

# Represents an incompatibility rule between two PartOptions.
# If 'part_option' is selected, 'restricted_part_option' cannot be selected.
class PartRestriction < ApplicationRecord
  # --- Associations ---
  # Explicitly define the associations based on the foreign keys.
  belongs_to :part_option, class_name: 'PartOption'
  belongs_to :restricted_part_option, class_name: 'PartOption'

  # --- Validations ---
  # Ensure the two linked options are not the same.
  validate :options_must_be_different
  # Ensure the inverse restriction doesn't already exist (enforce symmetry).
  validate :inverse_restriction_does_not_exist, on: :create

  private

  def options_must_be_different
    if part_option_id == restricted_part_option_id
      errors.add(:base, "A part option cannot restrict itself.")
      # Using :base adds the error to the object overall, not a specific attribute.
      # Alternatively, add to one of the IDs:
      # errors.add(:restricted_part_option_id, "cannot be the same as the primary part option")
    end
  end

  def inverse_restriction_does_not_exist
    # Check if a restriction exists where the options are swapped.
    # Use 'exists?' for efficiency (doesn't load the record).
    if PartRestriction.exists?(part_option_id: restricted_part_option_id, restricted_part_option_id: part_option_id)
      errors.add(:base, "The inverse restriction (where the restricted option restricts the primary option) already exists.")
    end
  end
end
