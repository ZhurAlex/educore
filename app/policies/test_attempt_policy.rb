# frozen_string_literal: true

# Ownership follows the parent Test (TestAttempt has no teacher_id of its
# own — the student/school_class side is shared, see Decision #10).
class TestAttemptPolicy < ApplicationPolicy
  def show? = owner?

  private

  def owner?
    user.present? && record.test.teacher_id == user.id
  end
end
