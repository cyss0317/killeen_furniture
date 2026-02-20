class ApplicationMailer < ActionMailer::Base
  default from: -> { "Killeen Furniture <#{ENV.fetch('ADMIN_EMAIL', 'noreply@killeenfurniture.com')}>" }
  layout "mailer"
end
