module Orders
  class ExternalCheckout
    Result = Struct.new(:order, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(cart:, checkout_params:, user:, payment_reference:)
      new(cart: cart, checkout_params: checkout_params, user: user, payment_reference: payment_reference).call
    end

    def initialize(cart:, checkout_params:, user:, payment_reference:)
      @cart              = cart
      @checkout_params   = checkout_params
      @user              = user
      @payment_reference = payment_reference
    end

    def call
      stock_error = validate_stock
      return Result.new(order: nil, error: stock_error) if stock_error

      shipping_result = ShippingCalculator.call(cart: @cart, zip_code: @checkout_params[:zip_code])
      return Result.new(order: nil, error: shipping_result.error) unless shipping_result.success?

      ActiveRecord::Base.transaction do
        order = build_order(shipping_result)
        order.save!
        build_order_items(order)
        decrement_stock(order)
        clear_cart

        Result.new(order: order, error: nil)
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(order: nil, error: e.message)
    rescue => e
      Result.new(order: nil, error: e.message)
    end

    private

    def validate_stock
      @cart.cart_items.includes(:product).each do |item|
        unless item.product.in_stock? && item.quantity <= item.product.stock_quantity
          return "#{item.product.name} has insufficient stock (#{item.product.stock_quantity} available)."
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
        user:                       @user,
        guest_email:                @checkout_params[:email],
        guest_name:                 @checkout_params[:full_name],
        guest_phone:                @checkout_params[:phone],
        status:                     :paid,
        payment_method:             :external,
        external_payment_reference: @payment_reference,
        source:                     :admin_manual,
        shipping_address: {
          full_name:      @checkout_params[:full_name],
          street_address: @checkout_params[:street_address],
          city:           @checkout_params[:city],
          state:          @checkout_params[:state],
          zip_code:       @checkout_params[:zip_code]
        },
        subtotal:        subtotal,
        tax_amount:      tax_amount,
        shipping_amount: shipping_cost,
        grand_total:     (subtotal + tax_amount + shipping_cost).round(2),
        delivery_zone:   shipping_result.zone
      )
    end

    def build_order_items(order)
      @cart.cart_items.includes(:product).each do |item|
        order.order_items.create!(
          product:      item.product,
          quantity:     item.quantity,
          unit_price:   item.product.selling_price,
          unit_cost:    item.product.base_cost,
          product_name: item.product.name,
          product_sku:  item.product.sku
        )
      end
    end

    def decrement_stock(order)
      order.order_items.each do |item|
        next unless item.product
        StockAdjustment.create!(
          product:         item.product,
          quantity_change: -item.quantity,
          reason:          "sale",
          admin_user:      @user
        )
      end
    end

    def clear_cart
      @cart.cart_items.destroy_all
    end
  end
end
