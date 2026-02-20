class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Method

  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_cart

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:first_name, :last_name, :phone])
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :phone])
  end

  private

  def current_cart
    @current_cart ||= find_or_create_cart
  end

  def find_or_create_cart
    if user_signed_in?
      current_user.cart || current_user.create_cart!
    else
      if session[:cart_id]
        Cart.find_by(id: session[:cart_id]) || create_guest_cart
      else
        create_guest_cart
      end
    end
  end

  def create_guest_cart
    cart = Cart.create!(session_id: SecureRandom.hex)
    session[:cart_id] = cart.id
    cart
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end

  def no_store
    response.set_header("Cache-Control", "no-store")
  end
end
