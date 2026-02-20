class OrderCreator
  Result = Struct.new(:order, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def self.call(cart:, checkout_params:, user: nil)
    new(cart: cart, checkout_params: checkout_params, user: user).call
  end

  def initialize(cart:, checkout_params:, user:)
    @cart            = cart
    @checkout_params = checkout_params
    @user            = user
  end

  def call
    stock_error = validate_stock
    return Result.new(order: nil, error: stock_error) if stock_error

    shipping_result = ShippingCalculator.call(cart: @cart, zip_code: @checkout_params[:zip_code])
    return Result.new(order: nil, error: shipping_result.error) unless shipping_result.success?

    order = build_order(shipping_result)

    ActiveRecord::Base.transaction do
      order.save!
      build_order_items(order)
    end

    Result.new(order: order, error: nil)
  rescue ActiveRecord::RecordInvalid => e
    Result.new(order: nil, error: e.message)
  end

  private

  def validate_stock
    @cart.cart_items.includes(:product).each do |item|
      unless item.product.in_stock? && item.quantity <= item.product.stock_quantity
        return "#{item.product.name} has insufficient stock. Only #{item.product.stock_quantity} available."
      end
    end
    nil
  end

  def build_order(shipping_result)
    tax_rate      = GlobalSetting.tax_rate / 100.0
    subtotal      = @cart.subtotal
    tax_amount    = (subtotal * tax_rate).round(2)
    shipping_cost = shipping_result.cost

    Order.new(
      user:             @user,
      guest_email:      @checkout_params[:email],
      guest_name:       @checkout_params[:full_name],
      guest_phone:      @checkout_params[:phone],
      status:           :pending,
      shipping_address: {
        full_name:      @checkout_params[:full_name],
        street_address: @checkout_params[:street_address],
        city:           @checkout_params[:city],
        state:          @checkout_params[:state],
        zip_code:       @checkout_params[:zip_code]
      },
      subtotal:         subtotal,
      tax_amount:       tax_amount,
      shipping_amount:  shipping_cost,
      grand_total:      (subtotal + tax_amount + shipping_cost).round(2),
      delivery_zone:    shipping_result.zone
    )
  end

  def build_order_items(order)
    @cart.cart_items.includes(:product).each do |item|
      order.order_items.create!(
        product:      item.product,
        quantity:     item.quantity,
        unit_price:   item.product.selling_price,
        product_name: item.product.name,
        product_sku:  item.product.sku
      )
    end
  end
end
