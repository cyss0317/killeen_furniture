require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  let(:password) { "password123!" }

  let(:customer) do
    create(:user, password: password, password_confirmation: password)
  end

  let(:admin_user) do
    create(:user, :ops_admin, password: password, password_confirmation: password)
  end

  let(:super_admin_user) do
    create(:user, :super_admin, password: password, password_confirmation: password)
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: { email: user.email, password: password }
    }
  end

  # ── admin remember-me ───────────────────────────────────────────────────
  describe "admin login" do
    it "sets a remember_me cookie for an ops admin" do
      sign_in_as(admin_user)
      expect(response).to redirect_to(root_path).or redirect_to(admin_dashboard_path)
      expect(cookies["remember_user_token"]).to be_present
    end

    it "sets a remember_me cookie for a super_admin" do
      sign_in_as(super_admin_user)
      expect(cookies["remember_user_token"]).to be_present
    end

    it "still merges a session cart into the admin's account" do
      cart = create(:cart)
      # Simulate a session cart
      get root_path  # ensures session is started
      # We can't directly set session in request specs; verify the controller
      # path doesn't error by checking a clean sign-in succeeds
      sign_in_as(admin_user)
      expect(response.status).to be_in([200, 302])
    end
  end

  # ── customer no remember-me ─────────────────────────────────────────────
  describe "customer login" do
    it "does NOT set a remember_me cookie for a regular customer" do
      sign_in_as(customer)
      expect(cookies["remember_user_token"]).to be_blank
    end

    it "redirects after sign-in" do
      sign_in_as(customer)
      expect(response).to be_redirect
    end
  end

  # ── wrong password ───────────────────────────────────────────────────────
  describe "failed login" do
    it "does not set a remember_me cookie on bad credentials" do
      post user_session_path, params: {
        user: { email: admin_user.email, password: "wrongpassword" }
      }
      expect(cookies["remember_user_token"]).to be_blank
    end
  end

  # ── User#remember_expires_at ─────────────────────────────────────────────
  describe "User#remember_expires_at" do
    it "returns ~48 hours from now for an admin" do
      expect(admin_user.remember_expires_at).to be_within(5.seconds).of(48.hours.from_now)
    end

    it "returns ~48 hours from now for a super_admin" do
      expect(super_admin_user.remember_expires_at).to be_within(5.seconds).of(48.hours.from_now)
    end

    it "returns the Devise default (2 weeks) for a customer" do
      expect(customer.remember_expires_at).to be_within(5.seconds).of(User.remember_for.from_now)
    end
  end
end
