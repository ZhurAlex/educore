# frozen_string_literal: true

class Question < ApplicationRecord
  # long_text deferred to "Later" — see docs/SPEC.md Decision #12.
  enum :answer_type, { multiple_choice: 0, short_text: 1, long_text: 2 }

  belongs_to :test
  has_many :responses, dependent: :destroy
  has_many :options, dependent: :destroy

  accepts_nested_attributes_for :options, allow_destroy: true, reject_if: proc { |attrs| attrs['body'].blank? }

  validates :body, presence: true
  validates :answer_type, presence: true
  validates :points, numericality: { greater_than_or_equal_to: 0.5 }
  validates :correct_answer, presence: true, if: :short_text?
  validate :points_in_half_point_increments
  validate :correct_options, if: :multiple_choice?

  # Auto-grading — see docs/SPEC.md "Question Types and Grading Logic".
  # Returns the points earned (0 or `points`); no partial credit in MVP.
  def grade(answer_text: nil, option_id: nil)
    correct =
      if multiple_choice?
        options.find(&:correct?)&.id == option_id&.to_i
      elsif short_text?
        normalize(answer_text) == normalize(correct_answer)
      end

    correct ? calculate_points : 0
  end

  private

  def calculate_points
    GeminiApiService.new.check_answer(body, answer_text) if long_text?

    points
  end

  def normalize(text)
    text.to_s.strip.downcase.gsub(/[[:punct:]]/, '')
  end

  def points_in_half_point_increments
    return if points.nil?

    errors.add(:points, 'must be in increments of 0.5') unless ((points * 2) % 1).zero?
  end

  def correct_options
    return if options.reject(&:marked_for_destruction?).one?(&:correct?)

    errors.add(:options, 'should be one correct option for multiple choice question')
  end
end
