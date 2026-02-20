class GlobalSetting < ApplicationRecord
  validates :key,   presence: true, uniqueness: { case_sensitive: false }
  validates :value, presence: true

  def self.[](key)
    find_by(key: key.to_s)&.value
  end

  def self.global_markup
    self["global_markup_percentage"].to_f
  end

  def self.tax_rate
    self["tax_rate"].to_f
  end

  def self.admin_notification_email
    self["admin_notification_email"] || ENV.fetch("ADMIN_EMAIL", "admin@example.com")
  end

  def self.set(key, value)
    record = find_or_initialize_by(key: key.to_s)
    record.value = value.to_s
    record.save!
    record
  end
end
