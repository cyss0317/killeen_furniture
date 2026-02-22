class EmployeePayEntry < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true

  validates :amount,        numericality: { greater_than: 0 }
  validates :employee_name, presence: true
  validates :paid_on,       presence: true

  scope :for_period, ->(range) { where(paid_on: range) }
  scope :recent,     -> { order(paid_on: :desc, created_at: :desc) }
end
