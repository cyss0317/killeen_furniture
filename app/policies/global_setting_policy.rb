class GlobalSettingPolicy < ApplicationPolicy
  def show?   = admin_or_above?
  def update? = super_admin?
end
