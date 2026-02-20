class Users::SessionsController < Devise::SessionsController
  def create
    super do |user|
      merge_session_cart_into_user(user)
    end
  end

  private

  def merge_session_cart_into_user(user)
    return unless session[:cart_id]

    session_cart = Cart.find_by(id: session[:cart_id])
    return unless session_cart

    user_cart = user.cart || user.create_cart!
    CartMerger.call(session_cart: session_cart, user_cart: user_cart)
    session.delete(:cart_id)
  end
end
