module SuperAdmin
  class EmployeesController < BaseController
    def index
      @employees = User.where(role: [ :admin, :super_admin ])
                       .order(:first_name, :last_name)
    end

    def update
      @user = User.find(params[:id])
      attrs = employee_params
      attrs[:admin_kind] = nil if attrs[:role] == "customer"
      if @user.update(attrs)
        respond_to do |format|
          format.turbo_stream { head :no_content }
          format.html { redirect_to super_admin_employees_path, notice: "#{@user.full_name} updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream { head :unprocessable_content }
          format.html { redirect_to super_admin_employees_path, alert: @user.errors.full_messages.to_sentence }
        end
      end
    end

    private

    def employee_params
      params.require(:user).permit(:role, :admin_kind, :pay_type, :pay_rate, :developer)
    end
  end
end
