module Orders
  class AdminCreate
    Result = Struct.new(:order, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...) = new(...).call

    def initialize(params:, admin:)
      @params = params
      @admin  = admin
    end

    def call
      validate_stock!
      ActiveRecord::Base.transaction do
        build_order
        build_order_items
        @order.save!
      end
      Result.new(order: @order)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: e.record.errors.full_messages.join(", "))
    rescue StandardError => e
      Result.new(error: e.message)
    end

    private

    def validate_stock!
      @line_items_with_products = @params[:line_items].map do |item|
        product = Product.find(item[:product_id])
        qty = item[:quantity].to_i
        raise "#{product.name}: insufficient stock (#{product.stock_quantity} available, #{qty} requested)" if qty > product.stock_quantity
        raise "#{product.name}: quantity must be at least 1" if qty < 1
        { product: product, quantity: qty }
      end
    end

    def build_order
      subtotal = calculated_subtotal
      shipping = @params[:shipping_amount].to_d
      tax      = (subtotal * (GlobalSetting.tax_rate / 100.0)).round(2)

      @order = Order.new(
        source:           (@params[:source].presence || "admin_manual"),
        user_id:          @params[:user_id].presence,
        guest_name:       @params[:guest_name].presence,
        guest_email:      @params[:guest_email].presence,
        guest_phone:      @params[:guest_phone].presence,
        shipping_address: @params[:shipping_address].to_h,
        subtotal:         subtotal,
        shipping_amount:  shipping,
        tax_amount:       tax,
        grand_total:      subtotal + shipping + tax,
        notes:            @params[:notes].presence,
        delivery_zone_id: @params[:delivery_zone_id].presence
      )
    end

    def build_order_items
      @line_items_with_products.each do |item|
        product = item[:product]
        @order.order_items.build(
          product:           product,
          quantity:          item[:quantity],
          unit_price:        product.selling_price,
          unit_cost:         product.base_cost,
          markup_percentage: product.markup_percentage,
          product_name:      product.name,
          product_sku:       product.sku
        )
      end
    end

    def calculated_subtotal
      @line_items_with_products.sum do |item|
        item[:product].selling_price * item[:quantity]
      end
    end
  end
end
