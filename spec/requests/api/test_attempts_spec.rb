# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::TestAttempts', type: :request do
  let(:token) { 'test-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(ENV).to receive(:fetch).with('ANALYTICS_API_KEY').and_return(token) }

  describe 'GET /api/test_attempts' do
    context 'authentication' do
      it 'is unauthorized without a token' do
        get api_test_attempts_path

        expect(response).to have_http_status(:unauthorized)
      end

      it 'is unauthorized with the wrong token' do
        get api_test_attempts_path, headers: { 'Authorization' => 'Bearer wrong-token' }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'succeeds with the correct token' do
        get api_test_attempts_path, headers: headers

        expect(response).to have_http_status(:success)
      end
    end

    context 'filtering' do
      let(:school_class_a) { create(:school_class) }
      let(:school_class_b) { create(:school_class) }
      let(:student_a) { create(:student, school_class: school_class_a) }
      let(:student_b) { create(:student, school_class: school_class_b) }
      let(:math_test) { create(:test, subject: :math) }
      let(:english_test) { create(:test, subject: :english) }

      let!(:attempt_a_math) { create(:test_attempt, :completed, student: student_a, test: math_test) }
      let!(:attempt_b_english) { create(:test_attempt, :completed, student: student_b, test: english_test) }

      def returned_ids
        response.parsed_body.pluck('id')
      end

      it 'returns everything when no filters are given' do
        get api_test_attempts_path, headers: headers

        expect(returned_ids).to contain_exactly(attempt_a_math.id, attempt_b_english.id)
      end

      it 'filters by test_id' do
        get api_test_attempts_path, params: { test_id: math_test.id }, headers: headers

        expect(returned_ids).to contain_exactly(attempt_a_math.id)
      end

      it 'filters by student_id' do
        get api_test_attempts_path, params: { student_id: student_b.id }, headers: headers

        expect(returned_ids).to contain_exactly(attempt_b_english.id)
      end

      it 'filters by school_class_id' do
        get api_test_attempts_path, params: { school_class_id: school_class_a.id }, headers: headers

        expect(returned_ids).to contain_exactly(attempt_a_math.id)
      end

      it 'filters by subject' do
        get api_test_attempts_path, params: { subject: 'english' }, headers: headers

        expect(returned_ids).to contain_exactly(attempt_b_english.id)
      end

      it 'combines filters with AND, not OR' do
        get api_test_attempts_path, params: { student_id: student_a.id, subject: 'english' }, headers: headers

        expect(returned_ids).to be_empty
      end
    end

    context 'response shape' do
      let(:test) { create(:test, subject: :english) }
      let(:question) do
        create(:question, test: test, body: 'Capital of France?', answer_type: :short_text, points: 2,
                          correct_answer: 'Paris')
      end
      let(:attempt) { create(:test_attempt, :completed, test: test) }

      before do
        create(:response, test_attempt: attempt, question: question, answer_text: 'paris',
                          points_awarded: 2, grading_status: :auto_graded)
      end

      it 'includes nested student, test, and response data' do
        get api_test_attempts_path, headers: headers

        body = response.parsed_body.first

        expect(body['student']).to include('id' => attempt.student.id, 'name' => attempt.student.full_name)
        expect(body['test']).to eq('id' => test.id, 'title' => test.title, 'subject' => 'english')
        expect(body['responses'].first).to include(
          'question' => 'Capital of France?',
          'answer' => 'paris',
          'points_awarded' => 2.0,
          'max_points' => 2.0,
          'grading_status' => 'auto_graded'
        )
      end
    end
  end
end
