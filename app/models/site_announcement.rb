class SiteAnnouncement < ApplicationRecord
  validates :message, :starts_at, :ends_at, presence: true
  validate :ends_after_starts

  scope :active_now, -> {
    where(active: true)
      .where("starts_at <= :now AND ends_at >= :now", now: Time.current)
      .order(starts_at: :desc)
  }

  private

  def ends_after_starts
    return unless starts_at && ends_at
    errors.add(:ends_at, "must be after the start date") if ends_at <= starts_at
  end
end
