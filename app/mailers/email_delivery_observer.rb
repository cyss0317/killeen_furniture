class EmailDeliveryObserver
  def self.delivered_email(message)
    order_id_str = message["X-Order-Id"]&.value
    EmailLog.create!(
      order_id:    order_id_str.present? ? order_id_str.to_i : nil,
      to:          message.to&.join(", ").to_s,
      subject:     message.subject.to_s,
      action_name: message["X-Mailer-Action"]&.value,
      sent_at:     Time.current
    )
  rescue => e
    Rails.logger.error "[EmailDeliveryObserver] #{e.message}"
  end
end
