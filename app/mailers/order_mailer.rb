class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order       = order
    @order_items = order.order_items

    mail(
      to:      order.customer_email,
      subject: "Order Confirmed — #{order.order_number} | Killeen Furniture"
    )
  end

  def admin_notification(order)
    @order       = order
    @order_items = order.order_items

    mail(
      to:      GlobalSetting.admin_notification_email,
      subject: "New Order: #{order.order_number} — #{number_to_currency(order.grand_total)}"
    )
  end
end
