class WorkOrderPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def create?
    user.admin? || user.manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.manager?
        scope.all
      else
        scope.where(assigned_to: user)
      end
    end
  end
end
