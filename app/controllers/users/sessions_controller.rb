class Users::SessionsController < Devise::SessionsController
  # Not auto-included in Devise 4.9 — gives us remember_me(resource).
  include Devise::Controllers::Rememberable

  def create
    super do |user|
      remember_me(user) if user.admin_or_above?
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
