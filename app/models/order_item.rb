class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity,     numericality: { greater_than: 0, only_integer: true }
  validates :unit_price,   numericality: { greater_than_or_equal_to: 0 }
  validates :product_name, :product_sku, presence: true

  def line_total
    unit_price * quantity
  end
end
