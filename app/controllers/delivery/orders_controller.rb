module Delivery
  class OrdersController < BaseController
    include Pagy::Method

    ALLOWED_STATUSES = %w[scheduled_for_delivery out_for_delivery delivered canceled].freeze

    before_action :set_order, only: [:show, :mark_delivered, :update_status]

    def index
      @status_filter = params[:status].presence_in(ALLOWED_STATUSES) || "scheduled_for_delivery"

      scope = policy_scope(Order)
               .where(status: @status_filter)
               .includes(:order_items, :user, :assigned_to)
               .recent

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

      User.where(role: :super_admin).each do |admin|
        OrderMailer.order_delivered(@order, admin).deliver_later
      end

      redirect_to delivery_orders_path, notice: "Order #{@order.order_number} marked as delivered."
    rescue => e
      redirect_to delivery_order_path(@order), alert: "Could not mark delivered: #{e.message}"
    end

    def update_status
      authorize @order, :update_status?

      new_status = params[:status].to_sym
      unless @order.allowed_next_statuses.include?(new_status)
        redirect_to delivery_order_path(@order), alert: "Invalid status transition."
        return
      end

      ActiveRecord::Base.transaction do
        @order.update!(status: new_status)
        @order.delivery_events.create!(
          status:     map_delivery_event_status(new_status),
          created_by: current_user,
          note:       "Status updated to #{new_status.to_s.humanize}"
        )
      end

      redirect_to delivery_order_path(@order), notice: "Order status updated to #{new_status.to_s.humanize.downcase}."
    rescue => e
      redirect_to delivery_order_path(@order), alert: "Could not update status: #{e.message}"
    end

    private

    def set_order
      @order = policy_scope(Order).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to delivery_orders_path, alert: "Order not found."
    end

    def map_delivery_event_status(order_status)
      case order_status
      when :out_for_delivery then :out_for_delivery
      when :delivered        then :delivered
      else :assigned
      end
    end
  end
end
