module Orders
  class AdminUpdate
    Result = Struct.new(:order, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(...) = new(...).call

    def initialize(order:, params:, admin:)
      @order  = order
      @params = params
      @admin  = admin
    end

    def call
      validate_line_items!
      ActiveRecord::Base.transaction do
        update_order
        replace_order_items
        @order.save!
      end
      Result.new(order: @order)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error: e.record.errors.full_messages.join(", "))
    rescue StandardError => e
      Result.new(error: e.message)
    end

    private

    def validate_line_items!
      @line_items_with_products = @params[:line_items]&.to_h.map do |_idx, item|
        qty = item[:quantity].to_i

        if item[:product_id].present?
          product = Product.find(item[:product_id])
          raise "#{product.name}: quantity must be at least 1" if qty < 1
          { product: product, quantity: qty }
        else
          name  = item[:custom_name].to_s.strip
          price = item[:unit_price].to_f
          raise "Custom item is missing a name" if name.blank?
          raise "Custom item '#{name}' must have a price greater than 0" if price <= 0
          raise "Custom item '#{name}': quantity must be at least 1" if qty < 1
          { custom: true, custom_name: name, unit_price: price, quantity: qty }
        end
      end
    end

    def update_order
      subtotal = calculated_subtotal
      shipping = @params[:shipping_amount].to_d
      discount = [@params[:discount_amount].to_d, 0].max
      tax      = (subtotal * (GlobalSetting.tax_rate / 100.0)).round(2)

      @order.assign_attributes(
        source:           @params[:source].presence || @order.source,
        pickup:           @params[:pickup] == "1",
        user_id:          @params[:user_id].presence,
        guest_name:       @params[:guest_name].presence,
        guest_email:      @params[:guest_email].presence,
        guest_phone:      @params[:guest_phone].presence,
        shipping_address: @params[:shipping_address].to_h,
        subtotal:         subtotal,
        shipping_amount:  shipping,
        discount_amount:  discount,
        tax_amount:       tax,
        grand_total:      [subtotal + shipping + tax - discount, 0].max,
        notes:            @params[:notes].presence,
        salesperson_id:   @params[:salesperson_id].presence
      )
    end

    def replace_order_items
      @order.order_items.destroy_all
      @line_items_with_products.each do |item|
        if item[:custom]
          @order.order_items.build(
            product:      nil,
            quantity:     item[:quantity],
            unit_price:   item[:unit_price],
            unit_cost:    0,
            product_name: item[:custom_name],
            product_sku:  "CUSTOM"
          )
        else
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
    end

    def calculated_subtotal
      @line_items_with_products.sum do |item|
        item[:custom] ? item[:unit_price] * item[:quantity] : item[:product].selling_price * item[:quantity]
      end
    end
  end
end
