class PurchaseOrder < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :purchase_order_items, dependent: :destroy

  enum :status, {
    draft:              0,
    submitted:          1,
    partially_received: 2,
    received:           3,
    canceled:           4
  }

  validates :reference_number, presence: true, uniqueness: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def total_cost
    purchase_order_items.sum { |i| i.unit_cost * i.quantity_ordered }
  end

  def fully_received?
    purchase_order_items.any? &&
      purchase_order_items.all? { |i| i.quantity_received >= i.quantity_ordered }
  end

  def receivable?
    submitted? || partially_received?
  end
end
