module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!
    before_action :redirect_delivery_admin!

    layout "admin"

    private

    def require_admin!
      unless current_user.admin_or_above?
        redirect_to root_path, alert: "You are not authorized to access the admin panel."
      end
    end

    def redirect_delivery_admin!
      if current_user.delivery_admin?
        redirect_to delivery_orders_path, alert: "Delivery admins access the delivery portal."
      end
    end
  end
end
