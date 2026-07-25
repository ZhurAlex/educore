class Option < ApplicationRecord
  belongs_to :question

  validates :body, presence: true
  validate :only_one_correct_option_per_question, if: :correct?

  private

  def only_one_correct_option_per_question
    return unless question.options.where(correct: true).where.not(id: id).exists?

    errors.add(:correct, "can only be set on one option per question")
  end
end
