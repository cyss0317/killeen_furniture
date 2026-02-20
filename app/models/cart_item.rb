class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validate  :product_is_published
  validate  :sufficient_stock

  def line_total
    product.selling_price * quantity
  end

  private

  def product_is_published
    return unless product
    errors.add(:product, "is not available") unless product.published?
  end

  def sufficient_stock
    return unless product
    if quantity > product.stock_quantity
      errors.add(:quantity, "exceeds available stock (#{product.stock_quantity} available)")
    end
  end
end
