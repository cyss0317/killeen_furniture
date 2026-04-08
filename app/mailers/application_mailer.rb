class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{APP_NAME} <#{ENV.fetch('ADMIN_EMAIL', 'noreply@warehousefurniture.com')}>" }
  layout "mailer"

  rescue_from StandardError do |e|
    Rails.logger.error "[Mailer] #{self.class}##{action_name} failed: #{e.class}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
  end
end
