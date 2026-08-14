# frozen_string_literal: true

class TestAttemptsController < ApplicationController
  # Public — the student takes the test here, no teacher auth. Access is
  # gated by session[:student_id] set during passcode verification (see
  # StudentPasscodesController), not by the app's real auth system.
  skip_before_action :authenticate_teacher!
  skip_around_action :switch_locale
  around_action :switch_locale_to_test

  before_action :set_test_attempt
  before_action :verify_owner!

  def show
    @questions = @test_attempt.test.questions.includes(:options).order(:id) if @test_attempt.in_progress?
  end

  def update
    if @test_attempt.in_progress?
      ActiveRecord::Base.transaction do
        @test_attempt.test.questions.find_each { |question| grade_question(question) }
        @test_attempt.update!(status: :completed, completed_at: Time.current)
        @test_attempt.recompute_score!
      end
    end

    render json: { redirect_url: test_attempt_path(@test_attempt) }
  end

  private

  def grade_question(question)
    answer = answer_params(question)
    response = @test_attempt.responses.find_or_initialize_by(question: question)
    response.answer_text = answer[:answer_text]
    response.option_id = answer[:option_id]
    response.points_awarded = question.grade(answer_text: answer[:answer_text], option_id: answer[:option_id])
    response.grading_status = :auto_graded
    response.save!
  end

  def set_test_attempt
    @test_attempt = TestAttempt.find(params[:id])
  end

  def verify_owner!
    head :forbidden unless session[:student_id] == @test_attempt.student_id
  end

  def answer_params(question)
    params.dig(:answers, question.id.to_s)&.permit(:answer_text, :option_id) || {}
  end

  def switch_locale_to_test(&)
    I18n.with_locale(TestAttempt.find(params[:id]).test.locale, &)
  end
end
