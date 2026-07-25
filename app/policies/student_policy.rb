# frozen_string_literal: true

# Shared, same as SchoolClassPolicy — see docs/SPEC.md Decision #10.
class StudentPolicy < ApplicationPolicy
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
