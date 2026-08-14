# frozen_string_literal: true

module TestAttemptsHelper
  def questions_as_json(questions)
    questions.map do |question|
      {
        id: question.id,
        body: question.body,
        answer_type: question.answer_type,
        points_label: t('test_attempts.show.points_suffix', count: display_points(question.points)),
        options: question.options.map do |option|
          {
            id: option.id,
            body: option.body
          }
        end
      }
    end.to_json
  end

  def translations_as_json
    I18n.t('test_attempts.show').to_json
  end

  private

  # Strips the trailing ".0" a BigDecimal like 2.0 would otherwise show,
  # while keeping real fractions (2.5) as they are.
  def display_points(points)
    points == points.to_i ? points.to_i : points
  end
end
