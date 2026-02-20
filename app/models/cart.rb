class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total_items
    cart_items.sum(:quantity)
  end

  def subtotal
    cart_items.includes(:product).sum { |item| item.product.selling_price * item.quantity }
  end

  def total_weight
    cart_items.includes(:product).sum { |item| (item.product.weight || 0) * item.quantity }
  end

  def empty?
    cart_items.none?
  end

  def item_count_for(product)
    cart_items.find_by(product: product)&.quantity || 0
  end
end
