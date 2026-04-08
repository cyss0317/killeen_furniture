class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def total_items
    cart_items.sum(:quantity)
  end

  def subtotal
    cart_items.joins(:product).sum("products.selling_price * cart_items.quantity")
  end

  def total_weight
    cart_items.joins(:product).sum("COALESCE(products.weight, 0) * cart_items.quantity")
  end

  def empty?
    cart_items.none?
  end

  def item_count_for(product)
    cart_items.find_by(product: product)&.quantity || 0
  end
end
