module Admin
  class EmployeePayController < BaseController
    before_action :require_super_admin!

    def index
      @period = params[:period].presence_in(%w[week month year]) || "month"
      @offset = params[:offset].to_i

      now = Time.current
      if @period == "month" && params[:month_val].present?
        target = Date.strptime(params[:month_val], "%Y-%m") rescue nil
        if target
          @offset = (target.year * 12 + target.month) - (now.year * 12 + now.month)
        end
      end

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

      @employees     = User.where(role: [:admin, :super_admin]).order(:first_name, :last_name)
      @entries       = EmployeePayEntry.for_period(@period_range).recent.includes(:created_by, :user)
      @period_total  = @entries.sum(:amount)
      @entry         = EmployeePayEntry.new(paid_on: Date.current)
    end

    def create
      user = User.find_by(id: params[:employee_pay_entry][:user_id])

      # For hourly employees, compute amount from hours × rate
      entry_params = pay_params
      if params[:pay_type_hint] == "hourly" && params[:hours_worked].present? && params[:rate].present?
        hours  = params[:hours_worked].to_f
        rate   = params[:rate].to_f
        amount = (hours * rate).round(2)
        entry_params = entry_params.merge(amount: amount, hours_worked: hours)
      end

      # Set employee_name from the selected user (fallback to whatever was supplied)
      if user
        entry_params = entry_params.merge(employee_name: user.full_name, user_id: user.id)
      end

      @entry = EmployeePayEntry.new(entry_params.merge(created_by: current_user))

      if @entry.save
        redirect_to admin_employee_pay_index_path(period: params[:period], offset: params[:offset]),
                    notice: "Pay entry added."
      else
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
      params.require(:employee_pay_entry).permit(:employee_name, :amount, :description, :paid_on, :user_id, :hours_worked)
    end
  end
end
