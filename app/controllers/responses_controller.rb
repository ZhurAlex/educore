# frozen_string_literal: true

class ResponsesController < ApplicationController
  before_action :set_response

  # Decision #13 (docs/SPEC.md): the teacher's only lever is overriding
  # points_awarded on an individual response — this cascades into the
  # attempt's auto-computed score/grade.
  def update
    authorize @response

    @response.update!(points_awarded: response_params[:points_awarded], grading_status: :teacher_overridden)
    @response.test_attempt.recompute_score!

    redirect_to attempt_path(@response.test_attempt), notice: t('.success')
  end

  private

  def set_response
    @response = Response.find(params[:id])
  end

  def response_params
    params.require(:response).permit(:points_awarded)
  end
end
