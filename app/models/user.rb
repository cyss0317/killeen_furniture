# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2]

  # Build or update a user record from an OmniAuth callback.
  # OAuth users skip email confirmation — the provider already verified it.
  def self.from_omniauth(auth)
    # auth.info may be sparse depending on token vs. userinfo path;
    # auth.extra.raw_info is the full Google userinfo payload.
    raw  = auth["extra"]["raw_info"] || {}
    email      = auth["info"]["email"].presence      || raw["email"].presence
    first_name = auth["info"]["first_name"].presence || raw["given_name"].presence  ||
                 (auth["info"]["name"] || raw["name"]).to_s.split(" ").first.presence
    last_name  = auth["info"]["last_name"].presence  || raw["family_name"].presence ||
                 (auth["info"]["name"] || raw["name"]).to_s.split(" ")[1..].join(" ").presence

    # 1. Returning OAuth user (provider + uid match)
    # 2. Existing email/password user signing in with Google for the first time
    # 3. Brand new user
    user = find_by(provider: auth.provider, uid: auth.uid) ||
    (email && find_by(email: email)) ||
    new

    user.provider   = auth.provider
    user.uid        = auth.uid
    user.email      = email      if user.email.blank? && email.present?
    user.first_name = first_name if user.first_name.blank? && first_name.present?
    user.last_name  = last_name  if user.last_name.blank? && last_name.present?
    user.password = Devise.friendly_token[0, 20] if user.new_record?

    # Google has already verified the email — skip confirmation regardless
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

    if user.save
      user
    else
      Rails.logger.error "[OmniAuth] User save failed: #{user.errors.full_messages.join(', ')}"
      nil
    end
  end

  EMAIL_COOLDOWN = 2.minutes

  # Throttle confirmation email resends — allow the initial post-create send
  # (account < 1 minute old) but block any resend within the cooldown window.
  def send_confirmation_instructions
    if confirmation_sent_at.present? &&
       confirmation_sent_at > EMAIL_COOLDOWN.ago &&
       created_at < 1.minute.ago
      return
    end
    super
  end

  # Throttle password-reset emails — reset_password_sent_at is only written
  # inside super, so we can safely gate on its existing value.
  def send_reset_password_instructions
    return if reset_password_sent_at.present? && reset_password_sent_at > EMAIL_COOLDOWN.ago
    super
  end

  def confirmation_required?
    Rails.env.production?
  end

  enum :role,       { customer: 0, admin: 1, super_admin: 2 }, default: :customer
  enum :admin_kind, { ops: 0, delivery: 1 }, prefix: :kind, allow_nil: true
  enum :pay_type,   { hourly: 0, monthly: 1 }, allow_nil: true

  has_many :addresses,        dependent: :destroy
  has_many :orders,           dependent: :nullify
  has_many :assigned_orders,  class_name: "Order", foreign_key: :assigned_to_id,  dependent: :nullify
  has_many :delivered_orders, class_name: "Order", foreign_key: :delivered_by_id, dependent: :nullify
  has_one  :cart,             dependent: :destroy
  has_many :stock_adjustments, foreign_key: :admin_user_id, dependent: :nullify

  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A[\d\s\-\(\)\+]+\z/, message: "must be a valid phone number" }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin_or_above?
    admin? || super_admin?
  end

  def delivery_admin?
    admin? && kind_delivery?
  end

  # Devise calls remember_expires_at to determine the cookie expiry.
  # Returns 48 h for admin/super_admin, 2 weeks (Devise default) for customers.
  def remember_expires_at
    duration = admin_or_above? ? 48.hours : self.class.remember_for
    duration.from_now
  end
end
