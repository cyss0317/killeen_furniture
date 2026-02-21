class ApplicationMailer < ActionMailer::Base
  default from: -> { "#{APP_NAME} <#{ENV.fetch('ADMIN_EMAIL', 'noreply@warehousefurniture.com')}>" }
  layout "mailer"
end
