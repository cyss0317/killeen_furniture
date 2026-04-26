class Users::RegistrationsController < Devise::RegistrationsController
  before_action :check_honeypot, only: :create

  protected

  def after_sign_up_path_for(resource)
    root_path
  end

  def after_inactive_sign_up_path_for(resource)
    root_path
  end

  private

  # Silently redirect bots that fill the hidden honeypot field.
  # Real users never see the field, so it will always be blank for them.
  def check_honeypot
    if params.dig(:user, :website).present?
      Rails.logger.warn("[Honeypot] Bot signup blocked from IP #{request.remote_ip}")
      redirect_to root_path and return
    end
  end
end
