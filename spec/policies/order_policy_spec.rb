require 'rails_helper'

RSpec.describe OrderPolicy do
  subject { described_class }

  # These users are stubbed (no DB hit) — used for action permission tests
  let(:super_admin)    { build_stubbed(:user, :super_admin) }
  let(:ops_admin)      { build_stubbed(:user, :ops_admin) }
  let(:delivery_admin) { build_stubbed(:user, :delivery_admin) }
  let(:customer)       { build_stubbed(:user) }

  let(:other_customer)      { build_stubbed(:user) }
  let(:order_for_customer)  { build_stubbed(:order, user: customer) }
  let(:order_for_other)     { build_stubbed(:order, user: other_customer) }
  let(:assigned_order)      { build_stubbed(:order, user: customer, assigned_to: delivery_admin, status: :scheduled_for_delivery) }
  let(:unassigned_order)    { build_stubbed(:order, user: customer, assigned_to: nil, status: :scheduled_for_delivery) }
  let(:delivered_order)     { build_stubbed(:order, user: customer, assigned_to: delivery_admin, status: :delivered) }

  describe "Scope" do
    # Scope tests need real DB records, so use create
    let!(:db_super_admin)    { create(:user, :super_admin) }
    let!(:db_delivery_admin) { create(:user, :delivery_admin) }
    let!(:db_ops_admin)      { create(:user, :ops_admin) }
    let!(:db_customer)       { create(:user) }

    it "returns all orders for super_admin" do
      create(:order)
      create(:order)
      scope = Pundit.policy_scope!(db_super_admin, Order)
      expect(scope.count).to eq(Order.count)
    end

    it "returns all orders for ops admin" do
      create(:order)
      scope = Pundit.policy_scope!(db_ops_admin, Order)
      expect(scope.count).to eq(Order.count)
    end

    it "returns only assigned orders for delivery admin" do
      other_delivery = create(:user, :delivery_admin)
      order_assigned     = create(:order, assigned_to: db_delivery_admin)
      _order_not_assigned = create(:order, assigned_to: other_delivery)
      scope = Pundit.policy_scope!(db_delivery_admin, Order)
      expect(scope.to_a).to eq([order_assigned])
    end

    it "returns only own orders for customer" do
      my_order    = create(:order, user: db_customer)
      _their_order = create(:order, user: create(:user))
      scope = Pundit.policy_scope!(db_customer, Order)
      expect(scope.to_a).to eq([my_order])
    end
  end

  describe "#assign?" do
    it "allows super_admin" do
      expect(subject.new(super_admin, order_for_customer)).to be_assign
    end

    it "denies delivery admin" do
      expect(subject.new(delivery_admin, order_for_customer)).not_to be_assign
    end

    it "denies ops admin" do
      expect(subject.new(ops_admin, order_for_customer)).not_to be_assign
    end

    it "denies customer" do
      expect(subject.new(customer, order_for_customer)).not_to be_assign
    end
  end

  describe "#mark_delivered?" do
    it "allows delivery admin for their assigned order" do
      expect(subject.new(delivery_admin, assigned_order)).to be_mark_delivered
    end

    it "denies delivery admin for unassigned order" do
      expect(subject.new(delivery_admin, unassigned_order)).not_to be_mark_delivered
    end

    it "allows super_admin for any non-delivered order" do
      expect(subject.new(super_admin, unassigned_order)).to be_mark_delivered
    end

    it "denies anyone for already-delivered order" do
      expect(subject.new(super_admin, delivered_order)).not_to be_mark_delivered
    end

    it "denies customer" do
      expect(subject.new(customer, assigned_order)).not_to be_mark_delivered
    end
  end

  describe "#show?" do
    it "allows customer to see their own order" do
      expect(subject.new(customer, order_for_customer)).to be_show
    end

    it "denies customer from seeing another's order" do
      expect(subject.new(customer, order_for_other)).not_to be_show
    end

    it "allows assigned delivery admin to see their assigned order" do
      expect(subject.new(delivery_admin, assigned_order)).to be_show
    end

    it "allows super_admin to see any order" do
      expect(subject.new(super_admin, order_for_other)).to be_show
    end
  end

  describe "#create?" do
    it "allows admin" do
      expect(subject.new(ops_admin, Order.new)).to be_create
    end

    it "denies customer" do
      expect(subject.new(customer, Order.new)).not_to be_create
    end
  end
end
