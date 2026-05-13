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
        find_or_create_guest_user
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

    def find_or_create_guest_user
      # Only applies to guest orders (no existing user_id)
      return if @params[:user_id].present?

      email = @params[:guest_email].to_s.strip.downcase
      return if email.blank?

      name  = @params[:guest_name].to_s.strip
      phone = @params[:guest_phone].to_s.strip
      first, *rest = name.split(" ")

      addr  = (@params[:shipping_address] || {}).to_h.transform_keys(&:to_s)

      user = User.find_by(email: email)

      if user
        user.update_columns(phone: phone) if phone.present? && user.phone.blank?
      else
        user = User.new(
          email:      email,
          first_name: first.presence || "Guest",
          last_name:  rest.join(" ").presence || "",
          phone:      phone.presence,
          password:   SecureRandom.hex(16),
          role:       :customer
        )
        user.skip_confirmation!
        user.save!
        Rails.logger.info "[AdminCreate] Created new customer: #{email}"
      end

      # Save delivery address if provided and user has none with this street
      if addr["street_address"].present?
        already_saved = user.addresses.any? do |a|
          a.street_address.downcase == addr["street_address"].downcase &&
          a.zip_code == addr["zip_code"].to_s
        end

        unless already_saved
          user.addresses.create!(
            full_name:      addr["full_name"].presence || name,
            street_address: addr["street_address"],
            city:           addr["city"].to_s,
            state:          addr["state"].to_s,
            zip_code:       addr["zip_code"].to_s,
            is_default:     user.addresses.none?
          )
          Rails.logger.info "[AdminCreate] Saved address for #{email}"
        end
      end

      @params = @params.merge(user_id: user.id.to_s)
    end

    def validate_stock!
      @line_items_with_products = @params[:line_items]&.to_h.map do |_idx, item|
        qty = item[:quantity].to_i

        if item[:product_id].present?
          product = Product.find(item[:product_id])
          raise "#{product.name}: insufficient stock (#{product.stock_quantity} available, #{qty} requested)" if qty > product.stock_quantity
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

    def build_order
      subtotal = calculated_subtotal
      shipping = @params[:shipping_amount].to_d
      discount = [@params[:discount_amount].to_d, 0].max
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
        discount_amount:  discount,
        tax_amount:       tax,
        grand_total:      [subtotal + shipping + tax - discount, 0].max,
        notes:            @params[:notes].presence,
        delivery_zone_id: @params[:delivery_zone_id].presence,
        salesperson_id:   @params[:salesperson_id].presence
      )
    end

    def build_order_items
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
        if item[:custom]
          item[:unit_price] * item[:quantity]
        else
          item[:product].selling_price * item[:quantity]
        end
      end
    end
  end
end
