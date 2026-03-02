class User < ApplicationRecord
  has_many :assigned_work_orders, class_name: "WorkOrder", foreign_key: :assigned_to_id

  validates :name, :email, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: %w[admin manager technician] }
end
