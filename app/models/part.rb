class Part < ApplicationRecord
  belongs_to :product
  has_many :part_options, dependent: :destroy
  validates :name, presence: true
end
