class Product < ApplicationRecord
    has_many :parts, dependent: :destroy
    validates :name, presence: true
end