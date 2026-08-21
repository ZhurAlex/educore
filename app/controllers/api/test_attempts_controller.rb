# frozen_string_literal: true

module Api
  class TestAttemptsController < Api::ApplicationController
    def index
      test_attempts = TestAttempt.includes(:student, :test, responses: %i[question option])
                                 .for_subject(attempts_params[:subject])
                                 .for_student(attempts_params[:student_id])
                                 .for_test(attempts_params[:test_id])
                                 .for_school_class(attempts_params[:school_class_id])
      render json: test_attempts.map { |ta| Api::TestAttemptSerializer.new(ta).as_json }
    end

    private

    def attempts_params
      params.permit(:student_id, :test_id, :school_class_id, :subject)
    end
  end
end
