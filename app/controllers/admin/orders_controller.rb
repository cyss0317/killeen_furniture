module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :update_status, :assign_delivery]

    def index
      scope = Order.includes(:user, :order_items, :delivery_zone, :assigned_to).recent

      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.where(source: params[:source]) if params[:source].present?

      if params[:q].present?
        q = "%#{params[:q]}%"
        scope = scope.where("order_number ILIKE ? OR guest_email ILIKE ? OR guest_name ILIKE ?", q, q, q)
      end

      @pagy, @orders = pagy(:offset, scope, limit: 25)
      @status_counts = Order.group(:status).count
    end

    def show
      @order_items     = @order.order_items.includes(:product)
      @delivery_admins = User.where(role: :admin, admin_kind: :delivery).order(:first_name)
      @delivery_events = @order.delivery_events.includes(:created_by).order(created_at: :asc)
    end

    def new
      authorize Order, :create?
      @order          = Order.new
      @users          = User.order(:first_name, :last_name)
      @products       = Product.published.includes(:category).order(:name)
      @delivery_zones = DeliveryZone.active.order(:name)
    end

    def create
      authorize Order, :create?
      result = Orders::AdminCreate.call(params: order_create_params, admin: current_user)

      if result.success?
        redirect_to admin_order_path(result.order), notice: "Order #{result.order.order_number} created successfully."
      else
        @order          = Order.new
        @users          = User.order(:first_name, :last_name)
        @products       = Product.published.includes(:category).order(:name)
        @delivery_zones = DeliveryZone.active.order(:name)
        flash.now[:alert] = result.error
        render :new, status: :unprocessable_entity
      end
    end

    def update_status
      new_status = params[:status].to_sym

      unless @order.allowed_next_statuses.include?(new_status)
        redirect_to admin_order_path(@order), alert: "Invalid status transition."
        return
      end

      if @order.update(status: new_status)
        redirect_to admin_order_path(@order), notice: "Order status updated to #{@order.status.humanize.downcase}."
      else
        redirect_to admin_order_path(@order), alert: @order.errors.full_messages.to_sentence
      end
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
        line_items: [:product_id, :quantity]
      )[:line_items] || []

      shipping_address = params.require(:order).permit(
        shipping_address: [:full_name, :street_address, :city, :state, :zip_code]
      )[:shipping_address]

      base = params.require(:order).permit(
        :source, :user_id, :guest_name, :guest_email, :guest_phone,
        :notes, :shipping_amount, :delivery_zone_id
      )

      base.merge(line_items: line_items, shipping_address: shipping_address)
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
