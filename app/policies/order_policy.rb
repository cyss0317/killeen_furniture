class OrderPolicy < ApplicationPolicy
  def show?
    admin_or_above? || record.user == user
  end

  def update_status?
    admin_or_above? && record.editable_by_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.admin_or_above?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
