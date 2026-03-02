class Property < ApplicationRecord
  has_many :tenants, dependent: :destroy
  has_many :work_orders, dependent: :destroy

  validates :name, :address, :city, presence: true
  validates :units_count, numericality: { greater_than: 0 }

  scope :in_city, ->(city) { where(city: city) }
  scope :residential, -> { where(property_type: "residential") }
  scope :commercial, -> { where(property_type: "commercial") }
end
