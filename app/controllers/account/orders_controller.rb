module Account
  class OrdersController < BaseController
    def index
      @pagy, @orders = pagy(current_user.orders.recent, items: 10)
    end

    def show
      @order = current_user.orders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to account_orders_path, alert: "Order not found."
    end
  end
end
