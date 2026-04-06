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

  def self.delete_all
    PurchaseOrder.all.each do |po|
      po.purchase_order_items.delete_all
    end

    [ "B2589-44",
     "B1190-44",
     "B1190-72",
     "B1190-97",
     "B1190-31",
     "B2589-31",
     "B2589-53",
     "B2589-83",
     "B1190-92",
     "B376-92" ].each { |sku| Product.find_by(sku:)&.delete }

    super
  end
end
