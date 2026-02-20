class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :quantity,     numericality: { greater_than: 0, only_integer: true }
  validates :unit_price,   numericality: { greater_than_or_equal_to: 0 }
  validates :product_name, :product_sku, presence: true

  def line_total
    unit_price * quantity
  end

  def margin
    return nil if unit_cost.blank?
    unit_price - unit_cost
  end

  def margin_percentage
    return nil if unit_cost.blank? || unit_cost.zero?
    (margin / unit_cost * 100).round(1)
  end
end
