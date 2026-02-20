class Product < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :category
  has_rich_text :description
  has_many_attached :images
  has_many :cart_items,        dependent: :destroy
  has_many :order_items,       dependent: :nullify
  has_many :stock_adjustments, dependent: :destroy

  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft

  validates :name, :sku, :base_cost, :category, presence: true
  validates :sku, uniqueness: { case_sensitive: false }
  validates :base_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :markup_percentage, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  before_validation :normalize_sku
  before_create     :generate_qr_token
  before_save       :calculate_selling_price
  before_validation :set_markup_from_global, if: :markup_percentage_blank?

  scope :published,    -> { where(status: :published) }
  scope :featured,     -> { where(featured: true) }
  scope :in_stock,     -> { where("stock_quantity > 0") }
  scope :low_stock,    -> { where("stock_quantity > 0 AND stock_quantity <= 5") }
  scope :out_of_stock, -> { where(stock_quantity: 0) }
  scope :search_by,    ->(query) {
    return all unless query.present?
    where("name ILIKE :q OR brand ILIKE :q OR sku ILIKE :q OR short_description ILIKE :q",
          q: "%#{sanitize_sql_like(query)}%")
  }
  scope :by_category, ->(cat_id) { where(category_id: cat_id) if cat_id.present? }
  scope :price_range, ->(min, max) {
    scope = all
    scope = scope.where("selling_price >= ?", min.to_f) if min.present?
    scope = scope.where("selling_price <= ?", max.to_f) if max.present?
    scope
  }

  def in_stock?
    stock_quantity > 0
  end

  def large_item?
    weight.present? && weight >= 50
  end

  def primary_image
    images.first
  end

  def formatted_price
    ActionController::Base.helpers.number_to_currency(selling_price)
  end

  def formatted_base_cost
    ActionController::Base.helpers.number_to_currency(base_cost)
  end

  private

  def generate_qr_token
    self.qr_token ||= SecureRandom.urlsafe_base64(16)
  end

  def calculate_selling_price
    return unless base_cost.present? && markup_percentage.present?
    self.selling_price = (base_cost * (1 + markup_percentage / 100.0)).round(2)
  end

  def markup_percentage_blank?
    markup_percentage.to_f.zero?
  end

  def set_markup_from_global
    global_rate = GlobalSetting.global_markup
    self.markup_percentage = global_rate if global_rate > 0
  end

  def normalize_sku
    self.sku = sku.to_s.strip.upcase if sku.present?
  end
end
