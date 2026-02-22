module Admin
  class EmployeePayController < BaseController
    before_action :require_super_admin!

    def index
      @period = params[:period].presence_in(%w[week month year]) || "month"
      @offset = params[:offset].to_i

      now    = Time.current
      anchor = case @period
               when "week"  then now + @offset.weeks
               when "year"  then now + @offset.years
               else              now + @offset.months
               end

      @period_range = case @period
                      when "week"  then anchor.beginning_of_week.to_date..anchor.end_of_week.to_date
                      when "year"  then anchor.beginning_of_year.to_date..anchor.end_of_year.to_date
                      else              anchor.beginning_of_month.to_date..anchor.end_of_month.to_date
                      end

      @period_display = case @period
                        when "week"  then "Week of #{anchor.beginning_of_week.strftime('%b %-d')} – #{anchor.end_of_week.strftime('%b %-d, %Y')}"
                        when "year"  then anchor.strftime("%Y")
                        else              anchor.strftime("%B %Y")
                        end

      @entries       = EmployeePayEntry.for_period(@period_range).recent.includes(:created_by)
      @period_total  = @entries.sum(:amount)
      @entry         = EmployeePayEntry.new(paid_on: Date.current)
    end

    def create
      @entry = EmployeePayEntry.new(pay_params.merge(created_by: current_user))

      if @entry.save
        redirect_to admin_employee_pay_index_path(period: params[:period], offset: params[:offset]),
                    notice: "Pay entry added."
      else
        # Re-render index with the form errors
        @period = params[:period].presence_in(%w[week month year]) || "month"
        @offset = params[:offset].to_i
        redirect_to admin_employee_pay_index_path(period: @period, offset: @offset),
                    alert: @entry.errors.full_messages.to_sentence
      end
    end

    def destroy
      entry = EmployeePayEntry.find(params[:id])
      entry.destroy!
      redirect_to admin_employee_pay_index_path(period: params[:period], offset: params[:offset]),
                  notice: "Pay entry deleted."
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_employee_pay_index_path, alert: "Entry not found."
    end

    private

    def require_super_admin!
      unless current_user.super_admin?
        redirect_to admin_dashboard_path, alert: "Access denied."
      end
    end

    def pay_params
      params.require(:employee_pay_entry).permit(:amount, :employee_name, :description, :paid_on)
    end
  end
end
