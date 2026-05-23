Rails.application.config.after_initialize do
  ActionMailer::Base.register_observer(EmailDeliveryObserver)
end
