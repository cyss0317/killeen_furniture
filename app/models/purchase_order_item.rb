class PurchaseOrderItem < ApplicationRecord
  belongs_to :purchase_order
  belongs_to :product

  validates :quantity_ordered,  numericality: { greater_than: 0, only_integer: true }
  validates :quantity_received, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :unit_cost, numericality: { greater_than_or_equal_to: 0 }

  def remaining_quantity
    quantity_ordered - quantity_received
  end

  def line_cost
    unit_cost * quantity_ordered
  end
end
