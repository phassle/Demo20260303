class WorkOrder < ApplicationRecord
  belongs_to :property
  belongs_to :tenant, optional: true
  belongs_to :assigned_to, class_name: "User", optional: true

  validates :title, presence: true
  validates :status, inclusion: { in: %w[open in_progress completed cancelled] }
  validates :priority, inclusion: { in: %w[low normal high urgent] }

  scope :open_orders, -> { where(status: "open") }
  scope :unassigned, -> { where(assigned_to_id: nil) }
  scope :by_priority, -> { order(Arel.sql("CASE priority WHEN 'urgent' THEN 0 WHEN 'high' THEN 1 WHEN 'normal' THEN 2 WHEN 'low' THEN 3 END")) }

  validates :description, presence: true
end
