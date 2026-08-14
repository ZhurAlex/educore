# frozen_string_literal: true

class TestAttempt < ApplicationRecord
  # A distinct "graded" state returns once long_text/manual review is
  # reintroduced — see docs/SPEC.md Data Model note on TestAttempt.
  enum :status, { in_progress: 0, completed: 1 }

  belongs_to :student
  belongs_to :test
  has_many :responses, dependent: :destroy

  validates :started_at, presence: true
  # Decision #2 (docs/SPEC.md): one active attempt per (student, test) —
  # mirrors the DB partial unique index in the create_test_attempts migration.
  validates :test_id, uniqueness: {
    scope: :student_id,
    conditions: -> { where(status: statuses[:in_progress]) },
    message: :active_attempt_exists
  }, if: :in_progress?

  # Decision #13 (docs/SPEC.md): score is the auto-computed sum of
  # points_awarded; grade is score rounded up, never entered manually.
  def recompute_score!
    total = responses.sum(:points_awarded)
    update!(score: total, grade: total.ceil)
  end
end
