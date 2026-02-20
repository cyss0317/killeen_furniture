class StockAdjustment < ApplicationRecord
  belongs_to :product
  belongs_to :admin_user, class_name: "User", optional: true

  REASONS = %w[restock sale damage return admin_adjustment receipt_import].freeze

  validates :quantity_change, numericality: { other_than: 0 }
  validates :reason, presence: true, inclusion: { in: REASONS, message: "%{value} is not a valid reason" }

  after_create :apply_to_product

  scope :recent, -> { order(created_at: :desc) }

  private

  def apply_to_product
    product.increment!(:stock_quantity, quantity_change)
  end
end
