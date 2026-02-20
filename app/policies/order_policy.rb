class OrderPolicy < ApplicationPolicy
  def show?
    admin_or_above? || record.user == user || record.assigned_to == user
  end

  def create?
    admin_or_above?
  end

  def assign?
    super_admin?
  end

  def mark_delivered?
    return false if record.delivered?
    admin_or_above? && (user&.super_admin? || record.assigned_to == user)
  end

  def update_status?
    admin_or_above? && record.editable_by_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.super_admin?
        scope.all
      elsif user&.delivery_admin?
        scope.where(assigned_to_id: user.id)
      elsif user&.admin_or_above?
        scope.all
      elsif user
        scope.where(user: user)
      else
        scope.none
      end
    end
  end
end
