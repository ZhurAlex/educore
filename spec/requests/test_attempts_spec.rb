# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TestAttempts', type: :request do
  let(:school_class) { create(:school_class) }
  let(:student) { create(:student, school_class: school_class, birth_date: Date.new(2013, 3, 7)) }
  let(:test) { create(:test) }
  let(:assignment) { create(:test_assignment, test: test, school_class: school_class) }

  def sign_in_as_student!
    post student_passcode_path(assignment, student), params: { passcode: '0703' }
    TestAttempt.last
  end

  describe 'GET /test_attempts/:id' do
    it 'renders the question form for the owning student' do
      attempt = sign_in_as_student!

      get test_attempt_path(attempt)

      expect(response).to have_http_status(:success)
    end

    it 'is forbidden for a visitor without the matching session' do
      attempt = create(:test_attempt, student: student, test: test)

      get test_attempt_path(attempt)

      expect(response).to have_http_status(:forbidden)
    end

    it 'shows the per-question breakdown once the attempt is no longer in progress' do
      st_question = create(:question, test: test, answer_type: :short_text, body: 'Capital of France?',
                                      correct_answer: 'Paris', points: 2)

      attempt = sign_in_as_student!
      patch test_attempt_path(attempt), params: {
        answers: { st_question.id.to_s => { answer_text: 'london' } }
      }, as: :json

      get test_attempt_path(attempt)

      expect(response.body).to include(st_question.body)
      expect(response.body).to include('london')
      expect(response.body).to include('Paris')
    end

    it 'shows a placeholder for long_text answers still awaiting grading' do
      lt_question = create(:question, test: test, answer_type: :long_text, correct_answer: nil, points: 2)

      attempt = sign_in_as_student!
      patch test_attempt_path(attempt), params: {
        answers: { lt_question.id.to_s => { answer_text: 'some essay answer' } }
      }, as: :json

      get test_attempt_path(attempt)

      expect(response.body).to include('some essay answer')
      expect(response.body).to match(/reviewed|проверяется|перевіряється/)
    end
  end

  describe 'PATCH /test_attempts/:id' do
    it 'grades answers, completes the attempt, and returns a redirect_url' do
      mc_question = create(:question, :multiple_choice, test: test, points: 1)
      correct_option = mc_question.options.find(&:correct?)
      st_question = create(:question, test: test, answer_type: :short_text, correct_answer: 'Paris', points: 2)

      attempt = sign_in_as_student!

      patch test_attempt_path(attempt), params: {
        answers: {
          mc_question.id.to_s => { option_id: correct_option.id },
          st_question.id.to_s => { answer_text: 'paris' }
        }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['redirect_url']).to eq(test_attempt_path(attempt))

      attempt.reload
      expect(attempt).to be_evaluating
      expect(attempt.score).to eq(3)
      expect(attempt.grade).to eq(3)
      expect(attempt.responses.count).to eq(2)
    end

    it 'allows a blank answer and scores it 0, instead of erroring (Decision #13)' do
      mc_question = create(:question, :multiple_choice, test: test, points: 1)
      st_question = create(:question, test: test, answer_type: :short_text, correct_answer: 'Paris', points: 2)

      attempt = sign_in_as_student!

      patch test_attempt_path(attempt), params: {
        answers: {
          mc_question.id.to_s => { option_id: '' },
          st_question.id.to_s => { answer_text: '' }
        }
      }, as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['redirect_url']).to eq(test_attempt_path(attempt))

      attempt.reload
      expect(attempt).to be_evaluating
      expect(attempt.score).to eq(0)
      expect(attempt.responses.count).to eq(2)
    end

    it 'lets the student revisit their completed result (Decision #14, revised)' do
      attempt = sign_in_as_student!
      patch test_attempt_path(attempt), params: { answers: {} }, as: :json

      get test_attempt_path(attempt)
      expect(response).to have_http_status(:success)
      expect(response.body).to match(/Бали/)

      # results are re-visitable now — no longer cleared after one view
      get test_attempt_path(attempt)
      expect(response).to have_http_status(:success)
    end
  end
end
