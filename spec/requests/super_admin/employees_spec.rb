require "rails_helper"

RSpec.describe "SuperAdmin::Employees", type: :request do
  let(:password) { "password123!" }
  let(:super_admin_user) { create(:user, :super_admin, password: password, password_confirmation: password) }

  before do
    post user_session_path, params: { user: { email: super_admin_user.email, password: password } }
  end

  describe "GET /super_admin/employees/new" do
    it "renders the new employee form" do
      get new_super_admin_employee_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Employee")
    end
  end

  describe "POST /super_admin/employees" do
    it "creates an employee without an email" do
      expect {
        post super_admin_employees_path, params: {
          user: { first_name: "Jordan", last_name: "Lee", role: "admin", admin_kind: "ops" }
        }
      }.to change(User, :count).by(1)

      employee = User.order(:created_at).last
      expect(employee.first_name).to eq("Jordan")
      expect(employee.email).to match(/\Aemployee-.+@no-email\.local\z/)
      expect(response).to redirect_to(super_admin_employees_path)
    end

    it "creates an employee with a provided email" do
      post super_admin_employees_path, params: {
        user: { first_name: "Sam", last_name: "Rivera", email: "sam@example.com", role: "super_admin" }
      }

      employee = User.find_by(email: "sam@example.com")
      expect(employee).to be_present
      expect(employee.super_admin?).to be true
    end

    it "re-renders the form when invalid" do
      post super_admin_employees_path, params: {
        user: { first_name: "", last_name: "", role: "admin" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /super_admin/employees/:id" do
    let(:employee) { create(:user, :ops_admin, password: password, password_confirmation: password) }

    it "updates name and email fields" do
      patch super_admin_employee_path(employee), params: {
        user: { first_name: "Updated", last_name: "Name", email: "updated@example.com",
                role: "admin", admin_kind: "ops" }
      }
      employee.reload
      expect(employee.first_name).to eq("Updated")
      expect(employee.email).to eq("updated@example.com")
    end

    it "assigns a placeholder email when email is blanked out" do
      patch super_admin_employee_path(employee), params: {
        user: { first_name: employee.first_name, last_name: employee.last_name,
                email: "", role: "admin" }
      }
      employee.reload
      expect(employee.email).to match(/\Aemployee-.+@no-email\.local\z/)
    end
  end

  describe "DELETE /super_admin/employees/:id" do
    let!(:employee) { create(:user, :ops_admin, password: password, password_confirmation: password) }

    it "deletes the employee" do
      expect {
        delete super_admin_employee_path(employee)
      }.to change(User, :count).by(-1)
      expect(response).to redirect_to(super_admin_employees_path)
      expect(flash[:notice]).to include("removed")
    end

    it "refuses to delete the current user" do
      delete super_admin_employee_path(super_admin_user)
      expect(User.exists?(super_admin_user.id)).to be true
      expect(flash[:alert]).to include("cannot delete your own account")
    end
  end
end
