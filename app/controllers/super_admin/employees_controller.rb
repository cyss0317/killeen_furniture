module SuperAdmin
  class EmployeesController < BaseController
    def index
      @employees = User.where(role: [ :admin, :super_admin ])
                       .order(:first_name, :last_name)
    end

    def new
      @employee = User.new(role: :admin)
    end

    def create
      attrs = employee_create_params
      attrs[:role]       = attrs[:role].presence || "admin"
      attrs[:admin_kind] = nil if attrs[:admin_kind].blank?

      @employee = User.new(attrs.to_h.except("email"))
      @employee.email    = attrs[:email].to_s.strip.presence || generate_placeholder_email
      @employee.password = SecureRandom.hex(16)
      @employee.skip_confirmation!

      if @employee.save
        redirect_to super_admin_employees_path, notice: "#{@employee.full_name} added."
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      @user = User.find(params[:id])
      attrs = employee_params
      attrs[:admin_kind] = nil if attrs[:admin_kind].blank?
      attrs[:email] = generate_placeholder_email if attrs[:email].blank?
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

    def destroy
      @user = User.find(params[:id])

      if @user == current_user
        redirect_to super_admin_employees_path, alert: "You cannot delete your own account."
        return
      end

      name = @user.full_name
      @user.destroy!
      redirect_to super_admin_employees_path, notice: "#{name} has been removed."
    rescue ActiveRecord::InvalidForeignKey
      redirect_to super_admin_employees_path,
                  alert: "#{@user.full_name} cannot be deleted because they have associated records (orders, payments, etc.)."
    end

    private

    def employee_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone, :role, :admin_kind, :pay_type, :pay_rate, :developer)
    end

    def employee_create_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone, :role, :admin_kind, :pay_type, :pay_rate, :developer)
    end

    def generate_placeholder_email
      loop do
        candidate = "employee-#{SecureRandom.hex(6)}@no-email.local"
        break candidate unless User.exists?(email: candidate)
      end
    end
  end
end
