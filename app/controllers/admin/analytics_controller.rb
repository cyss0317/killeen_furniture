module Admin
  class AnalyticsController < BaseController
    def index
      @period    = params[:period].presence_in(%w[week month year]) || "month"
      @offset    = params[:offset].to_i
      @analytics = RevenueAnalyticsQuery.call(period: @period, offset: @offset)
    end
  end
end
