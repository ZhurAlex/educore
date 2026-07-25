# frozen_string_literal: true

# Test is the one entity with teacher_id — Pundit scopes here, not on
# SchoolClass/Student. See docs/SPEC.md Decision #10.
class TestPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = owner?
  def create? = user.present?
  def update? = owner?
  def destroy? = owner?

  class Scope < Scope
    def resolve
      scope.where(teacher: user)
    end
  end

  private

  def owner?
    user.present? && record.teacher_id == user.id
  end
end
