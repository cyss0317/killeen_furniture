module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    layout "admin"

    private

    def require_admin!
      unless current_user.admin_or_above?
        redirect_to root_path, alert: "You are not authorized to access the admin panel."
      end
    end
  end
end
