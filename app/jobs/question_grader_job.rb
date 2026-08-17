# frozen_string_literal: true

class QuestionGraderJob < ApplicationJob
  def perform(test_attempt_id)
    test_attempt = TestAttempt.find(test_attempt_id)
    responses = test_attempt.responses.pending.includes(:question)
    responses.each { |response| grade_response(response) }
    test_attempt.update!(status: :completed)
    test_attempt.recompute_score!
  end

  private

  def grade_response(response)
    question = response.question
    grade_result = question.grade(answer_text: response.answer_text, option_id: response.option_id)
    if grade_result.error.present?
      Rails.logger.error(grade_result.error)
      response.grading_status = :manual_check_required
    else
      response.points_awarded = grade_result.points
      response.feedback = grade_result.feedback
      response.grading_status = :llm_graded
    end

    response.save!
  end
end
