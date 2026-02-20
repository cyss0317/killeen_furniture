module Admin
  class SettingsController < BaseController
    before_action :require_super_admin!

    def show
      @settings = GlobalSetting.all.index_by(&:key)
    end

    def update
      params[:settings].each do |key, value|
        setting = GlobalSetting.find_by(key: key)
        setting&.update!(value: value.to_s.strip)
      end
      redirect_to admin_settings_path, notice: "Settings updated."
    end

    private

    def require_super_admin!
      unless current_user.super_admin?
        redirect_to admin_root_path, alert: "Super admin access required."
      end
    end
  end
end
