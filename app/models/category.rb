class Category < ApplicationRecord
  extend FriendlyId
  friendly_id :name, use: :slugged

  belongs_to :parent, class_name: "Category", optional: true
  has_many   :subcategories, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  has_many   :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parent_id, case_sensitive: false }

  scope :root_categories, -> { where(parent_id: nil).order(:position, :name) }
  scope :ordered,         -> { order(:position, :name) }

  def self.tree
    root_categories.includes(:subcategories)
  end

  def top_level?
    parent_id.nil?
  end
end
