module Admin
  class AnalyticsController < BaseController
    def index
      @period     = params[:period].presence_in(%w[week month year custom]) || "month"
      @offset     = params[:offset].to_i
      
      now = Time.current
      if @period == "month" && params[:month_val].present?
        target = Date.strptime(params[:month_val], "%Y-%m") rescue nil
        if target
          @offset = (target.year * 12 + target.month) - (now.year * 12 + now.month)
        end
      end
      @start_date = params[:start_date]
      @end_date   = params[:end_date]
      @analytics  = RevenueAnalyticsQuery.call(
                      period: @period,
                      offset: @offset,
                      start_date: @start_date,
                      end_date: @end_date
                    )
    end
  end
end
