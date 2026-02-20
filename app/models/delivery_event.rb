class DeliveryEvent < ApplicationRecord
  belongs_to :order
  belongs_to :created_by, class_name: "User", optional: true

  enum :status, {
    assigned:          0,
    out_for_delivery:  1,
    delivered:         2,
    failed:            3,
    rescheduled:       4
  }

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
