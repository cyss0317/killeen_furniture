class Address < ApplicationRecord
  belongs_to :user, optional: true

  validates :full_name, :street_address, :city, :state, :zip_code, presence: true
  validates :zip_code, format: { with: /\A\d{5}(-\d{4})?\z/, message: "must be a 5-digit ZIP code" }

  before_save :ensure_single_default, if: :is_default?

  scope :defaults_first, -> { order(is_default: :desc, created_at: :desc) }

  def to_h_for_order
    {
      full_name:      full_name,
      street_address: street_address,
      city:           city,
      state:          state,
      zip_code:       zip_code
    }
  end

  private

  def ensure_single_default
    return unless user
    user.addresses.where.not(id: id).update_all(is_default: false)
  end
end
