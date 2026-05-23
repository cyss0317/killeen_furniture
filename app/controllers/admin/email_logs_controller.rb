module Admin
  class EmailLogsController < BaseController
    before_action :require_developer!

    def index
      scope = EmailLog.includes(:order).order(sent_at: :desc)

      if params[:q].present?
        q = "%#{params[:q].strip}%"
        scope = scope.where("email_logs.to ILIKE :q OR email_logs.subject ILIKE :q", q: q)
      end

      if params[:action_name].present?
        scope = scope.where(action_name: params[:action_name])
      end

      @pagy, @logs = pagy(:offset, scope, limit: 50)
      @action_names = EmailLog::LABELS.map { |k, v| [v, k] }.sort_by(&:first)
    end
  end
end
