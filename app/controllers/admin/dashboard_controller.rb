module Admin
  class DashboardController < BaseController
    def index
      @today_orders   = Order.today.count
      @today_revenue  = Order.today.revenue.sum(:grand_total)
      @pending_orders = Order.where(status: :pending).count
      @paid_orders    = Order.where(status: :paid).count
      @low_stock      = Product.published.low_stock.includes(:images_attachments).limit(10)
      @total_products = Product.published.count

      @status_filter  = params[:status].presence_in(Order.statuses.keys)
      recent_scope    = Order.recent.includes(:user, :order_items)
      recent_scope    = recent_scope.where(status: @status_filter) if @status_filter
      @recent_orders  = recent_scope.limit(10)
    end
  end
end
