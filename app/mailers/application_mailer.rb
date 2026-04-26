class ApplicationMailer < ActionMailer::Base
  # ADMIN_EMAIL must be on the domain verified in Resend (e.g. noreply@warehousefurnituretx.com).
  default from:     -> { "#{APP_NAME} <#{ENV.fetch('MAIL_FROM', 'noreply@warehousefurnituretx.com')}>" },
          reply_to: -> { ENV.fetch('MAIL_REPLY_TO', ENV.fetch('MAIL_FROM', 'info@warehousefurnituretx.com')) }
  layout "mailer"

  rescue_from StandardError do |e|
    Rails.logger.error "[Mailer] #{self.class}##{action_name} failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
