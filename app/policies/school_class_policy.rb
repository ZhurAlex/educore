# frozen_string_literal: true

# SchoolClass/Student are shared across all teachers — no ownership check.
# See docs/SPEC.md Decision #10 ("Ownership model").
class SchoolClassPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = user.present?
  def create? = user.present?
  def update? = user.present?
  def destroy? = user.present?

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
