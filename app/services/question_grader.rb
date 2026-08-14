# frozen_string_literal: true

class QuestionGrader
  attr_reader :question

  def initialize(question)
    @question = question
  end

  def grade(answer_text: nil, option_id: nil)
    question.long_text? ? grade_by_llm(answer_text) : grade_by_comparison(answer_text, option_id)
  end

  private

  def grade_by_comparison(answer_text, option_id)
    correct =
      if question.multiple_choice?
        question.options.find(&:correct?)&.id == option_id&.to_i
      elsif question.short_text?
        normalize(answer_text) == normalize(question.correct_answer)
      end

    correct ? question.points : 0
  end

  def grade_by_llm(answer_text)
    return 0 if answer_text.blank?

    result = GeminiApiService.new.check_answer(question.body, answer_text)
    ((question.points * (result['score'] / 100.0)) * 2).round / 2.0
  end

  def normalize(text)
    text.to_s.strip.downcase.gsub(/[[:punct:]]/, '')
  end
end
