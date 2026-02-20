module Admin
  class OrdersController < BaseController
    before_action :set_order, only: [:show, :update_status]

    def index
      scope = Order.includes(:user, :order_items, :delivery_zone).recent

      scope = scope.where(status: params[:status]) if params[:status].present?

      if params[:q].present?
        q = "%#{params[:q]}%"
        scope = scope.where("order_number ILIKE ? OR guest_email ILIKE ? OR guest_name ILIKE ?", q, q, q)
      end

      @pagy, @orders = pagy(scope, items: 25)
      @status_counts = Order.group(:status).count
    end

    def show
      @order_items = @order.order_items.includes(:product)
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

    private

    def set_order
      @order = Order.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_orders_path, alert: "Order not found."
    end
  end
end
