module Admin
  class SettingsController < BaseController
    before_action :require_super_admin!

    def show
      @settings = GlobalSetting.all.index_by(&:key)
    end

    def update
      params[:settings].each do |key, value|
        GlobalSetting.set(key, value.to_s.strip)
      end
      redirect_to admin_settings_path, notice: "Settings updated."
    rescue => e
      Rails.logger.error "[Settings] Update failed: #{e.message}"
      redirect_to admin_settings_path, alert: "Failed to save settings: #{e.message}"
    end

    private

    def require_super_admin!
      unless current_user.super_admin?
        redirect_to admin_dashboard_path, alert: "Super admin access required."
      end
    end
  end
end
