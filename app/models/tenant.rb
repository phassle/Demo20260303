class Tenant < ApplicationRecord
  belongs_to :property
  has_many :work_orders, dependent: :nullify

  validates :name, :email, presence: true
  validates :email, uniqueness: true

  scope :active, -> { where("lease_end IS NULL OR lease_end >= ?", Date.current) }
end
