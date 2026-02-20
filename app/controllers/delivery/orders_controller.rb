module Delivery
  class OrdersController < BaseController
    include Pagy::Method

    before_action :set_order, only: [:show, :mark_delivered]

    def index
      scope = policy_scope(Order)
               .undelivered
               .includes(:order_items, :user, :assigned_to)
               .recent

      scope = scope.where(status: params[:status]) if params[:status].present?
      @pagy, @orders = pagy(:offset, scope, limit: 25)
    end

    def show
      authorize @order
      @order_items     = @order.order_items.includes(:product)
      @delivery_events = @order.delivery_events.includes(:created_by).order(created_at: :asc)
    end

    def mark_delivered
      authorize @order, :mark_delivered?

      ActiveRecord::Base.transaction do
        @order.update!(
          status:       :delivered,
          delivered_at: Time.current,
          delivered_by: current_user
        )
        @order.delivery_events.create!(
          status:     :delivered,
          created_by: current_user,
          note:       "Marked as delivered"
        )
      end

      redirect_to delivery_orders_path, notice: "Order #{@order.order_number} marked as delivered."
    rescue => e
      redirect_to delivery_order_path(@order), alert: "Could not mark delivered: #{e.message}"
    end

    private

    def set_order
      @order = policy_scope(Order).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to delivery_orders_path, alert: "Order not found."
    end
  end
end
