class CheckoutsController < ApplicationController
  before_action :ensure_cart_not_empty, only: [:show, :create]

  def show
    @default_address = current_user.addresses.find_by(is_default: true) if user_signed_in?
  end

  def create
    result = OrderCreator.call(
      cart:            current_cart,
      checkout_params: checkout_params,
      user:            current_user
    )

    unless result.success?
      render json: { error: result.error }, status: :unprocessable_entity
      return
    end

    @order = result.order

    begin
      intent = Stripe::PaymentIntent.create(
        amount:      (@order.grand_total * 100).to_i,
        currency:    "usd",
        description: "Killeen Furniture Order #{@order.order_number}",
        metadata:    {
          order_id:     @order.id,
          order_number: @order.order_number,
          customer:     @order.customer_name
        }
      )

      @order.update!(stripe_payment_intent_id: intent.id)
      session[:pending_order_id] = @order.id

      render json: { client_secret: intent.client_secret }
    rescue Stripe::StripeError => e
      @order.update!(status: :canceled)
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  def confirmation
    order_id = session.delete(:pending_order_id)
    @order   = Order.includes(:order_items).find_by(id: order_id)

    redirect_to root_path, alert: "Order not found." unless @order
  end

  def calculate_shipping
    result = ShippingCalculator.call(cart: current_cart, zip_code: params[:zip_code])
    render json: {
      success: result.success?,
      cost:    result.cost,
      error:   result.error
    }
  end

  private

  def checkout_params
    params.require(:checkout).permit(
      :full_name, :email, :phone,
      :street_address, :city, :state, :zip_code
    )
  end

  def ensure_cart_not_empty
    return unless current_cart.empty?
    respond_to do |format|
      format.html { redirect_to cart_path, alert: "Your cart is empty." }
      format.json { render json: { error: "Cart is empty" }, status: :unprocessable_entity }
    end
  end
end
