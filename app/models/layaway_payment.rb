class LayawayPayment < ApplicationRecord
  belongs_to :order
  belongs_to :collected_by, class_name: "User"

  validates :amount, numericality: { greater_than: 0 }
  validates :paid_at, presence: true

  before_validation :default_paid_at

  private

  def default_paid_at
    self.paid_at ||= Time.current
  end
end
