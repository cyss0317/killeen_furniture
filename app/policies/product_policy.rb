class ProductPolicy < ApplicationPolicy
  def qr_show?
    admin_or_above?
  end
end
