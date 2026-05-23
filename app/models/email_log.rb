class EmailLog < ApplicationRecord
  belongs_to :order, optional: true

  LABELS = {
    "confirmation"            => "Order Confirmation",
    "admin_notification"      => "Admin Notification",
    "delivery_assigned"       => "Delivery Assigned",
    "out_for_delivery"        => "Out for Delivery",
    "order_delivered"         => "Delivered (Admin)",
    "order_delivered_customer" => "Delivered (Customer)"
  }.freeze

  def label
    LABELS.fetch(action_name.to_s, action_name.to_s.humanize)
  end
end
