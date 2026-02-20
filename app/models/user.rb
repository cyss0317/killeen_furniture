# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role,       { customer: 0, admin: 1, super_admin: 2 }, default: :customer
  enum :admin_kind, { ops: 0, delivery: 1 }, prefix: :kind, allow_nil: true

  has_many :addresses,        dependent: :destroy
  has_many :orders,           dependent: :nullify
  has_many :assigned_orders,  class_name: "Order", foreign_key: :assigned_to_id,  dependent: :nullify
  has_many :delivered_orders, class_name: "Order", foreign_key: :delivered_by_id, dependent: :nullify
  has_one  :cart,             dependent: :destroy
  has_many :stock_adjustments, foreign_key: :admin_user_id, dependent: :nullify

  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A[\d\s\-\(\)\+]+\z/, message: "must be a valid phone number" }, allow_blank: true

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def admin_or_above?
    admin? || super_admin?
  end

  def delivery_admin?
    admin? && kind_delivery?
  end
end
