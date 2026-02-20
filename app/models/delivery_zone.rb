class DeliveryZone < ApplicationRecord
  has_many :orders, dependent: :nullify

  validates :name, presence: true
  validates :base_rate, numericality: { greater_than_or_equal_to: 0 }
  validates :zip_codes, presence: { message: "must include at least one ZIP code" }

  scope :active, -> { where(active: true) }

  def covers_zip?(zip)
    zip_codes.include?(zip.to_s.strip)
  end

  def self.find_by_zip(zip)
    active.where("? = ANY(zip_codes)", zip.to_s.strip).first
  end

  def zip_codes_text
    zip_codes.join(", ")
  end

  def zip_codes_text=(text)
    self.zip_codes = text.to_s.split(/[\s,]+/).map(&:strip).reject(&:blank?)
  end
end
