class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_stripe_signature

  def stripe
    case @event.type
    when "payment_intent.succeeded"
      handle_payment_success(@event.data.object)
    when "payment_intent.payment_failed"
      handle_payment_failure(@event.data.object)
    end

    head :ok
  end

  private

  def verify_stripe_signature
    payload    = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    secret     = ENV.fetch("STRIPE_WEBHOOK_SECRET", nil)

    unless secret
      Rails.logger.warn "[Stripe Webhook] STRIPE_WEBHOOK_SECRET not configured"
      head :ok and return
    end

    @event = Stripe::Webhook.construct_event(payload, sig_header, secret)
  rescue JSON::ParserError => e
    Rails.logger.error "[Stripe Webhook] JSON parse error: #{e.message}"
    render json: { error: "Invalid JSON" }, status: :bad_request
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.error "[Stripe Webhook] Signature verification failed: #{e.message}"
    render json: { error: "Invalid signature" }, status: :bad_request
  end

  def handle_payment_success(intent)
    order = Order.find_by(stripe_payment_intent_id: intent.id)
    return unless order&.pending?

    ActiveRecord::Base.transaction do
      order.update!(status: :paid)
      decrement_stock(order)
      clear_cart_for_order(order)
    end

    OrderMailer.confirmation(order).deliver_later
    OrderMailer.admin_notification(order).deliver_later
  rescue => e
    Rails.logger.error "[Stripe Webhook] Failed to process payment success for #{intent.id}: #{e.message}"
    raise e
  end

  def handle_payment_failure(intent)
    order = Order.find_by(stripe_payment_intent_id: intent.id)
    order&.update!(status: :canceled)
  end

  def decrement_stock(order)
    order.order_items.each do |item|
      next unless item.product

      StockAdjustment.create!(
        product:         item.product,
        quantity_change: -item.quantity,
        reason:          "sale",
        admin_user:      nil
      )
    end
  end

  def clear_cart_for_order(order)
    if order.user
      order.user.cart&.cart_items&.destroy_all
    end
  end
end
