# frozen_string_literal: true

# Ownership follows the test the response belongs to, via its attempt.
class ResponsePolicy < ApplicationPolicy
  def update? = owner?

  private

  def owner?
    user.present? && record.test_attempt.test.teacher_id == user.id
  end
end
