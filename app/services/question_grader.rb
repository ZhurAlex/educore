# frozen_string_literal: true

class QuestionGrader
  attr_reader :question

  GradeResult = Data.define(:points, :feedback, :error) do
    def initialize(points: 0, feedback: nil, error: nil)
      super
    end
  end

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
    GradeResult.new(
      points: correct ? question.points : 0
    )
  end

  def grade_by_llm(answer_text)
    return GradeResult.new if answer_text.blank?

    begin
      result = GeminiApiService.new.check_answer(question.body, answer_text, question.correct_answer)
    rescue GeminiApiService::GradingError => e
      return GradeResult.new(error: e.message)
    end

    GradeResult.new(
      points: ((question.points * (result['score'] / 100.0)) * 2).round / 2.0,
      feedback: result['feedback']
    )
  end

  def normalize(text)
    text.to_s.strip.downcase.gsub(/[[:punct:]]/, '')
  end
end
