# frozen_string_literal: true

# Ownership follows the parent Test (TestAssignment has no teacher_id of
# its own — SchoolClass is shared, see docs/SPEC.md Decision #10).
class TestAssignmentPolicy < ApplicationPolicy
  def create? = owner?
  def destroy? = owner?

  private

  def owner?
    user.present? && record.test.teacher_id == user.id
  end
end
