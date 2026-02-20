class CartMerger
  def self.call(session_cart:, user_cart:)
    new(session_cart: session_cart, user_cart: user_cart).call
  end

  def initialize(session_cart:, user_cart:)
    @session_cart = session_cart
    @user_cart    = user_cart
  end

  def call
    return @user_cart unless @session_cart.present?

    @session_cart.cart_items.each do |session_item|
      existing = @user_cart.cart_items.find_by(product_id: session_item.product_id)

      if existing
        new_qty = existing.quantity + session_item.quantity
        new_qty = [new_qty, session_item.product.stock_quantity].min
        existing.update!(quantity: new_qty)
      else
        session_item.update!(cart_id: @user_cart.id)
      end
    end

    @session_cart.destroy
    @user_cart
  end
end
