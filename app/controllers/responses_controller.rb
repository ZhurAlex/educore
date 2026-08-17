# frozen_string_literal: true

class ResponsesController < ApplicationController
  before_action :set_response

  # Decision #13 (docs/SPEC.md): the teacher's levers on an individual
  # response are points_awarded (cascades into the attempt's auto-computed
  # score/grade) and feedback (shown to the student, whether it started as
  # Gemini's text or the teacher's own note).
  def update
    authorize @response

    @response.update!(response_params.merge(grading_status: :teacher_overridden))
    @response.test_attempt.recompute_score!

    redirect_to attempt_path(@response.test_attempt), notice: t('.success')
  end

  private

  def set_response
    @response = Response.find(params[:id])
  end

  def response_params
    params.require(:response).permit(:points_awarded, :feedback)
  end
end
