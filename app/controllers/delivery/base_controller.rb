module Delivery
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin_access!

    layout "admin"

    private

    def require_admin_access!
      unless current_user&.admin_or_above?
        redirect_to root_path, alert: "You are not authorized to access this area."
      end
    end
  end
end
