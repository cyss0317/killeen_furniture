# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user   = user
    @record = record
  end

  def index?   = admin_or_above?
  def show?    = admin_or_above?
  def create?  = admin_or_above?
  def new?     = create?
  def update?  = admin_or_above?
  def edit?    = update?
  def destroy? = super_admin?

  class Scope
    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  def admin_or_above? = user&.admin_or_above?
  def super_admin?    = user&.super_admin?
end
