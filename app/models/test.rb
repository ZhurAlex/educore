# frozen_string_literal: true

class Test < ApplicationRecord
  # MVP locales — see docs/SPEC.md Decision #5. UI chrome only; test content
  # (title/questions) stays in whatever language the teacher wrote it in.
  LOCALES = %w[uk ru en].freeze

  belongs_to :teacher
  has_many :test_assignments, dependent: :destroy
  has_many :school_classes, through: :test_assignments
  has_many :questions, dependent: :destroy
  has_many :test_attempts, dependent: :destroy

  validates :title, presence: true
  validates :locale, presence: true, inclusion: { in: LOCALES }
end
