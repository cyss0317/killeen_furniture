module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [ :show, :edit, :update, :update_status, :update_customer, :update_address, :assign_delivery, :assign_commission, :resend_confirmation, :print_receipt ]

    SORTABLE_COLUMNS = %w[order_number created_at grand_total status].freeze

    def index
      scope = Order.includes(:user, :order_items, :delivery_zone, :assigned_to)

      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(source: params[:source]) if params[:source].present?

      @year = params[:year].presence || Time.current.year.to_s
      @month = params[:month].presence

      if @year.present?
        if @month.present?
          begin
            start_date = Date.strptime("#{@year}-#{@month}", "%Y-%m")
            scope = scope.where(created_at: start_date.beginning_of_month.beginning_of_day..start_date.end_of_month.end_of_day)
          rescue ArgumentError
            # Invalid format, ignore
          end
        else
          begin
            start_date = Date.strptime(@year, "%Y")
            scope = scope.where(created_at: start_date.beginning_of_year.beginning_of_day..start_date.end_of_year.end_of_day)
          rescue ArgumentError
            # Invalid format, ignore
          end
        end
      end

      if params[:q].present?
        q = "%#{params[:q].strip}%"
        scope = scope.left_joins(:user).where(
          "orders.order_number ILIKE :q OR orders.guest_email ILIKE :q OR " \
          "orders.guest_name ILIKE :q OR orders.guest_phone ILIKE :q OR " \
          "users.email ILIKE :q OR " \
          "(users.first_name || ' ' || users.last_name) ILIKE :q OR " \
          "users.first_name ILIKE :q OR users.last_name ILIKE :q",
          q: q
        ).distinct
      end

      if params[:address].present?
        addr = "%#{params[:address].strip}%"
        scope = scope.where(
          "(orders.shipping_address->>'street_address') ILIKE :a OR " \
          "(orders.shipping_address->>'city') ILIKE :a OR " \
          "(orders.shipping_address->>'state') ILIKE :a OR " \
          "(orders.shipping_address->>'zip_code') ILIKE :a",
          a: addr
        )
      end

      scope = scope.where("grand_total >= ?", params[:min_price].to_f) if params[:min_price].present?
      scope = scope.where("grand_total <= ?", params[:max_price].to_f) if params[:max_price].present?

      @sort      = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
      scope      = scope.reorder("orders.#{@sort} #{@direction}")

      @pagy, @orders = pagy(:offset, scope, limit: 25)
      @status_counts = Order.group(:status).count
    end

    def show
      @order_items      = @order.order_items.includes(:product)
      @delivery_admins  = User.where(role: :admin, admin_kind: :delivery).order(:first_name)
      @delivery_events  = @order.delivery_events.includes(:created_by).order(created_at: :asc)
      @layaway_payments = @order.layaway_payments.includes(:collected_by).order(paid_at: :asc)
      @salespeople      = User.where(role: [ User.roles[:admin], User.roles[:super_admin] ])
                             .where.not(admin_kind: User.admin_kinds[:delivery])
                             .order(:first_name, :last_name)
    end

    def new
      authorize Order, :create?
      @order          = Order.new
      @users          = User.where.not(confirmed_at: nil).order(:first_name, :last_name)
      @salespeople    = User.where(role: [ User.roles[:admin], User.roles[:super_admin] ])
                           .where.not(admin_kind: User.admin_kinds[:delivery])
                           .order(:first_name, :last_name)
      @products       = Product.includes(:category).order(:name)
      @delivery_zones = DeliveryZone.active.order(:name)
      @categories     = Category.order(:name)
      @colors         = Product.where.not(color: [ nil, "" ]).distinct.pluck(:color).sort
      @form_defaults  = { salesperson_id: current_user.id }
    end

    def create
      authorize Order, :create?
      result = Orders::AdminCreate.call(params: order_create_params, admin: current_user)

      if result.success?
        OrderMailer.confirmation(result.order).deliver_now if result.order.customer_email.present?
        redirect_to admin_order_path(result.order), notice: "Order #{result.order.order_number} created successfully."
      else
        @order          = Order.new
        @users          = User.where.not(confirmed_at: nil).order(:first_name, :last_name)
        @salespeople    = User.where(role: [ User.roles[:admin], User.roles[:super_admin] ])
                             .where.not(admin_kind: User.admin_kinds[:delivery])
                             .order(:first_name, :last_name)
        @products       = Product.includes(:category).order(:name)
        @delivery_zones = DeliveryZone.active.order(:name)
        @categories     = Category.order(:name)
        @colors         = Product.where.not(color: [ nil, "" ]).distinct.pluck(:color).sort
        @submitted_line_items = (params.dig(:order, :line_items) || {}).values.filter_map do |i|
          if i[:product_id].present?
            { product_id: i[:product_id], quantity: i[:quantity].to_i }
          elsif i[:custom_name].present?
            { custom: true, custom_name: i[:custom_name], unit_price: i[:unit_price].to_f, quantity: i[:quantity].to_i }
          end
        end

        # Preserve submitted form values so the form re-renders pre-filled.
        # Shipping address is submitted as "[shipping_address][...]" by the
        # fieldless form builder (no model scope), hence the bracket key.
        sa = params["[shipping_address]"]&.permit(:full_name, :street_address, :city, :state, :zip_code)&.to_h || {}
        @form_defaults = {
          source:                  params[:source],
          payment_method:          params[:payment_method],
          customer_type:           params[:customer_type],
          user_id:                 params[:user_id],
          guest_first_name:        params[:guest_first_name],
          guest_last_name:         params[:guest_last_name],
          guest_email:             params[:guest_email],
          guest_phone:             params[:guest_phone],
          notes:                   params[:notes],
          shipping_amount:         params[:shipping_amount],
          discount_amount:         params[:discount_amount],
          salesperson_id:          params[:salesperson_id],
          pickup:                  params[:pickup],
          shipping_full_name:      sa[:full_name],
          shipping_street_address: sa[:street_address],
          shipping_city:           sa[:city],
          shipping_state:          sa[:state],
          shipping_zip_code:       sa[:zip_code]
        }

        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @order, :update?
      unless @order.pending?
        redirect_to admin_order_path(@order), alert: "Only pending orders can be edited."
        return
      end
      @users          = User.where.not(confirmed_at: nil).order(:first_name, :last_name)
      @salespeople    = User.where(role: [ User.roles[:admin], User.roles[:super_admin] ])
                           .where.not(admin_kind: User.admin_kinds[:delivery])
                           .order(:first_name, :last_name)
      @products       = Product.includes(:category).order(:name)
      @delivery_zones = DeliveryZone.active.order(:name)
      @categories     = Category.order(:name)
      @colors         = Product.where.not(color: [ nil, "" ]).distinct.pluck(:color).sort
      addr            = @order.shipping_address || {}
      @form_defaults  = {
        source:                  @order.source,
        salesperson_id:          @order.salesperson_id,
        pickup:                  @order.pickup? ? "1" : nil,
        customer_type:           @order.user_id? ? "existing" : "guest",
        user_id:                 @order.user_id,
        guest_first_name:        @order.guest_name.to_s.split(" ", 2).first,
        guest_last_name:         @order.guest_name.to_s.split(" ", 2)[1].presence,
        guest_email:             @order.guest_email,
        guest_phone:             @order.guest_phone,
        notes:                   @order.notes,
        shipping_amount:         @order.shipping_amount,
        discount_amount:         @order.discount_amount,
        shipping_street_address: addr["street_address"],
        shipping_city:           addr["city"],
        shipping_state:          addr["state"],
        shipping_zip_code:       addr["zip_code"]
      }
      @submitted_line_items = @order.order_items.map { |i| { product_id: i.product_id.to_s, quantity: i.quantity } }
    end

    def update
      authorize @order, :update?
      unless @order.pending?
        redirect_to admin_order_path(@order), alert: "Only pending orders can be edited."
        return
      end

      result = Orders::AdminUpdate.call(order: @order, params: order_create_params, admin: current_user)

      if result.success?
        redirect_to admin_order_path(result.order), notice: "Order #{result.order.order_number} updated."
      else
        @users          = User.where.not(confirmed_at: nil).order(:first_name, :last_name)
        @salespeople    = User.where(role: [ User.roles[:admin], User.roles[:super_admin] ])
                             .where.not(admin_kind: User.admin_kinds[:delivery])
                             .order(:first_name, :last_name)
        @products       = Product.includes(:category).order(:name)
        @delivery_zones = DeliveryZone.active.order(:name)
        @categories     = Category.order(:name)
        @colors         = Product.where.not(color: [ nil, "" ]).distinct.pluck(:color).sort
        @submitted_line_items = (params.dig(:order, :line_items) || {}).values.filter_map do |i|
          if i[:product_id].present?
            { product_id: i[:product_id], quantity: i[:quantity].to_i }
          elsif i[:custom_name].present?
            { custom: true, custom_name: i[:custom_name], unit_price: i[:unit_price].to_f, quantity: i[:quantity].to_i }
          end
        end
        sa = params["[shipping_address]"]&.permit(:full_name, :street_address, :city, :state, :zip_code)&.to_h || {}
        @form_defaults = {
          source:                  params[:source],
          customer_type:           params[:customer_type],
          user_id:                 params[:user_id],
          guest_first_name:        params[:guest_first_name],
          guest_last_name:         params[:guest_last_name],
          guest_email:             params[:guest_email],
          guest_phone:             params[:guest_phone],
          notes:                   params[:notes],
          shipping_amount:         params[:shipping_amount],
          discount_amount:         params[:discount_amount],
          salesperson_id:          params[:salesperson_id],
          shipping_street_address: sa[:street_address],
          shipping_city:           sa[:city],
          shipping_state:          sa[:state],
          shipping_zip_code:       sa[:zip_code]
        }
        flash.now[:alert] = result.error
        render :edit, status: :unprocessable_entity
      end
    end

    def update_status
      new_status = params[:status].to_sym

      unless @order.allowed_next_statuses.include?(new_status)
        redirect_to admin_order_path(@order), alert: "Invalid status transition."
        return
      end

      attrs = { status: new_status }
      if new_status == :delivered
        attrs[:delivered_at] = Time.current
        attrs[:delivered_by] = current_user
      end

      if @order.update(attrs)
        case new_status
        when :out_for_delivery
          OrderMailer.out_for_delivery(@order).deliver_now
        when :delivered
          admin_email = ENV["ADMIN_EMAIL"].presence
          if admin_email
            admin = User.find_by(email: admin_email)
            OrderMailer.order_delivered(@order, admin).deliver_now if admin
          end
          OrderMailer.order_delivered_customer(@order).deliver_now
        end
        redirect_to admin_order_path(@order), notice: "Order status updated to #{@order.status.humanize.downcase}."
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
      end
    end

    def update_address
      addr = {
        "full_name"      => params[:full_name].to_s.strip,
        "street_address" => params[:street_address].to_s.strip,
        "city"           => params[:city].to_s.strip,
        "state"          => params[:state].to_s.strip,
        "zip_code"       => params[:zip_code].to_s.strip
      }

      required_fields = %w[street_address city state zip_code]
      missing = addr.slice(*required_fields).select { |_, v| v.blank? }.keys
      if missing.any?
        redirect_to admin_order_path(@order), alert: "#{missing.map(&:humanize).to_sentence} can't be blank."
        return
      end

      if @order.update(shipping_address: addr)
        redirect_to admin_order_path(@order), notice: "Delivery address updated."
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
      end
    end

    def update_customer
      new_email = params[:guest_email].to_s.strip.presence
      new_name  = params[:guest_name].presence
      new_phone = params[:guest_phone].presence

      if @order.user
        google_user = @order.user.provider == "google_oauth2"

        unless google_user
          if new_email.present?
            @order.user.update_columns(email: new_email, updated_at: Time.current)
          elsif new_email.nil?
            # blank submitted — email comes from user account, can't clear it
          end
        end

        if @order.update(guest_name: new_name, guest_phone: new_phone)
          msg = google_user ? "Customer info updated. Email is managed by Google and cannot be changed here." : "Customer info updated."
          redirect_to admin_order_path(@order), notice: msg
        else
          redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
        end
      else
        # Guest order — email column is owned by this order, nil is allowed
        if @order.update(guest_name: new_name, guest_email: new_email, guest_phone: new_phone)
          redirect_to admin_order_path(@order), notice: "Customer info updated."
        else
          redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
        end
      end
    end

    def resend_confirmation
      OrderMailer.confirmation(@order).deliver_now
      redirect_to admin_order_path(@order), notice: "Confirmation email resent to #{@order.customer_email}."
    end

    def print_receipt
      @order_items = @order.order_items.includes(:product)
      render layout: "print"
    end

    def assign_commission
      authorize @order, :assign_commission?
      salesperson_id = params[:salesperson_id].presence
      salesperson    = salesperson_id ? User.find(salesperson_id) : nil
      @order.update!(salesperson: salesperson)
      name = salesperson ? salesperson.full_name : "none"
      redirect_to admin_order_path(@order), notice: "Commission assigned to #{name}."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_order_path(@order), alert: "Salesperson not found."
    end

    def assign_delivery
      authorize @order, :assign?
      assigned_to = User.find(params[:assigned_to_id])
      Orders::AssignDelivery.call(order: @order, assigned_to: assigned_to, assigned_by: current_user)
      redirect_to admin_order_path(@order), notice: "Order assigned to #{assigned_to.full_name}."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_order_path(@order), alert: "Delivery admin not found."
    rescue => e
      redirect_to admin_order_path(@order), alert: e.message
    end

    def calculate_shipping
      zip_code   = params[:zip_code].to_s.strip
      item_data  = (params[:line_items] || []).select { |i| i[:product_id].present? && i[:quantity].to_i > 0 }
      cart_items = item_data.map { |i| CartItemProxy.new(Product.find(i[:product_id]), i[:quantity].to_i) }
      cart_proxy = CartProxy.new(cart_items)
      result = ShippingCalculator.call(cart: cart_proxy, zip_code: zip_code)

      if result.success?
        render json: { cost: result.cost, zone_name: result.zone.name, error: nil }
      else
        render json: { cost: nil, zone_name: nil, error: result.error }
      end
    end

    private

    def set_order
      @order = Order.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_orders_path, alert: "Order not found."
    end

    def order_create_params
      line_items = params.require(:order).permit(
        line_items: [ :product_id, :quantity, :custom_name, :unit_price ]
      )[:line_items] || []

      # shipping_address = params.require("[shipping_address]").permit(
      #   shipping_address: [:full_name, :street_address, :city, :state, :zip_code]
      # )[:shipping_address]

      shipping_address = (params["[shipping_address]"]&.permit(:full_name, :street_address, :city, :state, :zip_code) || {}).to_h
      # base = params.require(:order).permit(
      #   :source, :user_id, :guest_name, :guest_email, :guest_phone,
      #   :notes, :shipping_amount, :discount_amount, :delivery_zone_id
      # )
      base = params.permit(:source, :customer_type, :user_id, :guest_first_name, :guest_last_name,
                           :guest_email, :guest_phone, :salesperson_id, :notes, :shipping_amount,
                           :discount_amount, :delivery_zone_id, :pickup, :payment_method)
      first = base.delete(:guest_first_name).to_s.strip
      last  = base.delete(:guest_last_name).to_s.strip
      base  = base.merge(guest_name: [first, last].reject(&:blank?).join(" ").presence)
      base.to_unsafe_h.merge(line_items: line_items, shipping_address: shipping_address).with_indifferent_access
    end

    # Lightweight proxies so ShippingCalculator works with manual order data
    CartItemProxy = Struct.new(:product, :quantity) do
      def includes(*_args) = self   # no-op to satisfy includes(:product) call
    end

    class CartProxy
      def initialize(cart_items)
        @cart_items = cart_items
      end

      def cart_items
        # Return an object that supports .includes(:product).count { ... }
        CartItemCollection.new(@cart_items)
      end

      def total_items
        @cart_items.sum(&:quantity)
      end

      def total_weight
        @cart_items.sum { |ci| (ci.product.weight || 0) * ci.quantity }
      end
    end

    class CartItemCollection
      def initialize(items)
        @items = items
      end

      def includes(*_args)
        self
      end

      def count(&block)
        block ? @items.count(&block) : @items.count
      end

      def each(&block)
        @items.each(&block)
      end
    end
  end
end
