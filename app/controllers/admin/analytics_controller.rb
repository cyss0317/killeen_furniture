module Admin
  class AnalyticsController < BaseController
    def index
      @period    = params[:period].presence_in(%w[week month year]) || "month"
      @analytics = RevenueAnalyticsQuery.call(period: @period)
    end
  end
end
