# frozen_string_literal: true

class Test < ApplicationRecord
  LOCALES = %w[uk ru en].freeze

  enum :subject, { math: 0, english: 1 }

  belongs_to :teacher
  has_many :test_assignments, dependent: :destroy
  has_many :school_classes, through: :test_assignments
  has_many :questions, dependent: :destroy
  has_many :test_attempts, dependent: :destroy

  validates :title, presence: true
  validates :locale, presence: true, inclusion: { in: LOCALES }
  validates :subject, presence: true
end
