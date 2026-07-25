# frozen_string_literal: true

# Ownership follows the parent Test (Question has no teacher_id of its own).
class QuestionPolicy < ApplicationPolicy
  def create? = owner?
  def update? = owner?
  def destroy? = owner?

  private

  def owner?
    user.present? && record.test.teacher_id == user.id
  end
end
