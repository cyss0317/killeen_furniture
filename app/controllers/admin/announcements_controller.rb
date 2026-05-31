module Admin
  class AnnouncementsController < BaseController
    before_action :require_super_admin!
    before_action :set_announcement, only: [:edit, :update, :destroy]

    def index
      @announcements = SiteAnnouncement.order(starts_at: :desc)
    end

    def new
      @announcement = SiteAnnouncement.new(
        starts_at: Time.current.beginning_of_day,
        ends_at:   Time.current.end_of_day
      )
    end

    def create
      @announcement = SiteAnnouncement.new(announcement_params)
      if @announcement.save
        redirect_to admin_announcements_path, notice: "Announcement created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @announcement.update(announcement_params)
        redirect_to admin_announcements_path, notice: "Announcement updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @announcement.destroy
      redirect_to admin_announcements_path, notice: "Announcement deleted."
    end

    private

    def set_announcement
      @announcement = SiteAnnouncement.find(params[:id])
    end

    def announcement_params
      params.require(:site_announcement).permit(:message, :starts_at, :ends_at, :active)
    end

    def require_super_admin!
      unless current_user.super_admin?
        redirect_to admin_dashboard_path, alert: "Super admin access required."
      end
    end
  end
end
