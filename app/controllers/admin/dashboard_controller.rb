module Admin
  class DashboardController < BaseController
    def index
      @today_orders   = Order.today.count
      @today_revenue  = Order.today.revenue.sum(:grand_total)
      @pending_orders = Order.where(status: :pending).count
      @paid_orders    = Order.where(status: :paid).count
      @low_stock      = Product.published.low_stock.includes(:images_attachments).limit(10)
      @recent_orders  = Order.recent.includes(:user, :order_items).limit(10)
      @total_products = Product.published.count
    end
  end
end
