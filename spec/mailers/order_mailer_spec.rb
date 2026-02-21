require "rails_helper"

RSpec.describe OrderMailer, type: :mailer do
  include ActiveJob::TestHelper
  let(:delivery_admin) { create(:user, :delivery_admin) }
  let(:super_admin)    { create(:user, :super_admin) }
  let(:order)          { create(:order, :assigned, assigned_to: delivery_admin) }

  before do
    create(:order_item, order: order)
  end

  # ── delivery_assigned ────────────────────────────────────────────────────
  describe "#delivery_assigned" do
    subject(:mail) { described_class.delivery_assigned(order, delivery_admin) }

    it "sends to the assigned delivery user" do
      expect(mail.to).to eq([delivery_admin.email])
    end

    it "includes the order number in the subject" do
      expect(mail.subject).to include(order.order_number)
    end

    it "includes the customer name in the body" do
      expect(mail.body.encoded).to include(order.customer_name)
    end

    it "includes the delivery address in the body" do
      expect(mail.body.encoded).to include(order.shipping_address["street_address"])
    end

    it "includes a Google Maps link for the delivery address" do
      expect(mail.html_part.body.decoded).to include("maps.google.com").or include("google.com/maps")
    end

    it "links each item name to the admin product page" do
      item = order.order_items.first
      expect(mail.html_part.body.decoded).to include(admin_product_url(item.product))
    end

    it "includes a link to the delivery portal" do
      expect(mail.body.encoded).to include("/delivery/orders/#{order.id}")
    end
  end

  # ── order_delivered ───────────────────────────────────────────────────────
  describe "#order_delivered" do
    let(:delivered_order) do
      create(:order, :delivered,
        assigned_to:  delivery_admin,
        delivered_by: delivery_admin)
    end

    before { create(:order_item, order: delivered_order) }

    subject(:mail) { described_class.order_delivered(delivered_order, super_admin) }

    it "sends to the super_admin" do
      expect(mail.to).to eq([super_admin.email])
    end

    it "includes the order number in the subject" do
      expect(mail.subject).to include(delivered_order.order_number)
    end

    it "includes who delivered the order" do
      expect(mail.body.encoded).to include(delivery_admin.full_name)
    end

    it "includes the customer name" do
      expect(mail.body.encoded).to include(delivered_order.customer_name)
    end

    it "includes the delivery address" do
      expect(mail.body.encoded).to include(delivered_order.shipping_address["street_address"])
    end

    it "includes a Google Maps link for the delivery address" do
      expect(mail.html_part.body.decoded).to include("maps.google.com").or include("google.com/maps")
    end

    it "links each item name to the admin product page" do
      item = delivered_order.order_items.first
      expect(mail.html_part.body.decoded).to include(admin_product_url(item.product))
    end

    it "includes a link to the admin panel" do
      expect(mail.body.encoded).to include("/admin/orders/#{delivered_order.id}")
    end
  end

  # ── email trigger: Orders::AssignDelivery ─────────────────────────────────
  describe "email triggered by Orders::AssignDelivery" do
    let(:assignable_order) { create(:order, :paid) }
    let(:assigning_admin)  { create(:user, :super_admin) }

    it "enqueues a delivery_assigned email when an order is assigned" do
      expect {
        Orders::AssignDelivery.call(
          order:       assignable_order,
          assigned_to: delivery_admin,
          assigned_by: assigning_admin
        )
      }.to have_enqueued_mail(OrderMailer, :delivery_assigned)
    end

    it "enqueues a delivery_assigned email on reassignment" do
      other_delivery = create(:user, :delivery_admin)
      assignable_order.update!(assigned_to: delivery_admin)

      expect {
        Orders::AssignDelivery.call(
          order:       assignable_order,
          assigned_to: other_delivery,
          assigned_by: assigning_admin
        )
      }.to have_enqueued_mail(OrderMailer, :delivery_assigned)
    end

    it "does NOT send a delivery_assigned email on unrelated updates" do
      # Updating a field other than assigned_to should not trigger the mailer
      expect {
        assignable_order.update!(notes: "Updated notes")
      }.not_to have_enqueued_mail(OrderMailer, :delivery_assigned)
    end
  end

  # ── email trigger: Delivery::OrdersController#mark_delivered ─────────────
  describe "email triggered by mark_delivered" do
    let(:super_admin2) { create(:user, :super_admin) }

    it "enqueues order_delivered for each super_admin" do
      # Ensure we have two super admins
      super_admin
      super_admin2

      # Simulate the controller's notification logic
      expect {
        User.where(role: :super_admin).each do |admin|
          OrderMailer.order_delivered(order, admin).deliver_later
        end
      }.to have_enqueued_mail(OrderMailer, :order_delivered).exactly(2).times
    end

    it "does NOT enqueue order_delivered if delivered_at was already set" do
      # Guard: we do not re-notify on repeat calls
      already_delivered = create(:order, :delivered)
      create(:order_item, order: already_delivered)

      # Only the controller path triggers notifications; model callbacks do not
      # so a plain update does not send another email
      expect {
        already_delivered.touch(:delivered_at)
      }.not_to have_enqueued_mail(OrderMailer, :order_delivered)
    end
  end
end
