class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order       = order
    @order_items = order.order_items

    mail(
      to:      order.customer_email,
      subject: "Order Confirmed — #{order.order_number} | #{APP_NAME}"
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

  # Sent to the delivery person when an order is assigned (or reassigned) to them.
  def delivery_assigned(order, delivery_user)
    @order         = order
    @order_items   = order.order_items.includes(:product)
    @delivery_user = delivery_user

    mail(
      to:      delivery_user.email,
      subject: "New delivery assigned: Order #{order.order_number}"
    )
  end

  # Sent to the customer when their order is out for delivery.
  def out_for_delivery(order)
    @order       = order
    @order_items = order.order_items.includes(:product)

    mail(
      to:      order.customer_email,
      subject: "Your order is out for delivery! — #{order.order_number}"
    )
  end

  # Sent to all super_admins when an order is marked as delivered.
  def order_delivered(order, super_admin)
    @order       = order
    @order_items = order.order_items.includes(:product)
    @super_admin = super_admin

    mail(
      to:      super_admin.email,
      subject: "Order delivered: #{order.order_number}"
    )
  end

  # Sent to the customer when their order is marked as delivered.
  def order_delivered_customer(order)
    @order       = order
    @order_items = order.order_items.includes(:product)

    mail(
      to:      order.customer_email,
      subject: "Your order has been delivered — #{order.order_number}"
    )
  end
end
