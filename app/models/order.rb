class Order < ApplicationRecord
  belongs_to :user,         optional: true
  belongs_to :delivery_zone, optional: true
  belongs_to :assigned_to,  class_name: "User", optional: true
  belongs_to :delivered_by, class_name: "User", optional: true
  belongs_to :salesperson,  class_name: "User", optional: true
  has_many   :order_items,      dependent: :destroy
  has_many   :delivery_events,  dependent: :destroy
  has_many   :layaway_payments, dependent: :destroy

  enum :status, {
    pending:                0,
    paid:                   1,
    scheduled_for_delivery: 2,
    out_for_delivery:       3,
    delivered:              4,
    canceled:               5,
    refunded:               6
  }, default: :pending

  enum :source, {
    web_customer: 0,
    admin_manual: 1,
    phone:        2,
    in_store:     3
  }, default: :web_customer, prefix: :source

  enum :payment_method, {
    stripe:   0,
    external: 1,
    layaway:  2
  }, default: :stripe, prefix: :payment

  before_create :generate_order_number

  validates :shipping_address, presence: true, unless: :pickup?
  validates :grand_total, numericality: { greater_than_or_equal_to: 0 }

  scope :recent,      -> { order(created_at: :desc) }
  scope :today,       -> { where(created_at: Time.current.beginning_of_day..) }
  scope :revenue,     -> { where(status: [:paid, :scheduled_for_delivery, :out_for_delivery, :delivered]) }
  scope :undelivered, -> { where.not(status: :delivered) }

  STATUS_TRANSITIONS = {
    pending:                %i[paid canceled],
    paid:                   %i[scheduled_for_delivery canceled refunded],
    scheduled_for_delivery: %i[out_for_delivery canceled],
    out_for_delivery:       %i[delivered],
    delivered:              %i[refunded],
    canceled:               [],
    refunded:               []
  }.freeze

  def customer_email
    guest_email.presence || user&.email
  end

  def customer_name
    guest_name.presence || user&.full_name
  end

  def customer_phone
    guest_phone.presence || user&.phone
  end

  def editable_by_admin?
    !delivered? && !refunded?
  end

  def allowed_next_statuses
    STATUS_TRANSITIONS[status.to_sym] || []
  end

  def total_paid
    layaway_payments.sum(:amount)
  end

  def balance_due
    [grand_total - total_paid, 0].max
  end

  def layaway_paid_in_full?
    total_paid >= grand_total
  end

  def shipping_address_line
    addr = shipping_address
    "#{addr["street_address"]}, #{addr["city"]}, #{addr["state"]} #{addr["zip_code"]}"
  end

  private

  def generate_order_number
    loop do
      self.order_number = "KF-#{Time.current.year}-#{SecureRandom.alphanumeric(8).upcase}"
      break unless Order.exists?(order_number: order_number)
    end
  end

end
