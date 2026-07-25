class AttemptsController < ApplicationController
  before_action :set_test, only: [:index]
  before_action :set_attempt, only: [:show]

  def index
    # Explicit :show? — a bare `authorize @test` here would resolve to
    # TestPolicy#index? (named after this action), which only checks
    # "signed in", not ownership. We need the ownership check.
    authorize @test, :show?
    @attempts = @test.test_attempts.includes(:student).order(:created_at)
  end

  def show
    authorize @attempt
    @responses = @attempt.responses.includes(:question, :option).sort_by { |r| r.question_id }
  end

  private

  def set_test
    @test = Test.find(params[:test_id])
  end

  def set_attempt
    @attempt = TestAttempt.find(params[:id])
  end
end
