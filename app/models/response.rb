# frozen_string_literal: true

class Response < ApplicationRecord
  # pending_review/llm_graded return with long_text — see docs/SPEC.md
  # Decision #12.
  enum :grading_status, { auto_graded: 0, teacher_overridden: 1 }

  belongs_to :test_attempt
  belongs_to :question
  # Nullable: only multiple_choice responses have an option; short_text
  # responses answer via answer_text instead.
  belongs_to :option, optional: true

  validates :question_id, uniqueness: { scope: :test_attempt_id }
end
