class PurchaseOrderPolicy < ApplicationPolicy
  def index?  = super_admin?
  def show?   = super_admin?
  def new?    = super_admin?
  def create? = super_admin?

  def receive?
    super_admin? && record.receivable?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      user&.super_admin? ? scope.all : scope.none
    end
  end
end
