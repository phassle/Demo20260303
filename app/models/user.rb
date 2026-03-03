class User < ApplicationRecord
  has_many :assigned_work_orders, class_name: 'WorkOrder', foreign_key: :assigned_to_id,
                                  dependent: :nullify, inverse_of: :assigned_to

  validates :name, :email, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: %w[admin manager technician] }

  before_create :generate_api_token

  def admin?
    role == 'admin'
  end

  def manager?
    role == 'manager'
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
