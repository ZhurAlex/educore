# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Questions', type: :request do
  let(:teacher) { create(:teacher) }
  let(:test) { create(:test, teacher: teacher) }

  before { sign_in teacher }

  describe 'POST /tests/:test_id/questions' do
    it 'creates a short_text question' do
      expect do
        post test_questions_path(test), params: {
          question: { body: '2+2=?', answer_type: 'short_text', points: 1, correct_answer: '4' }
        }
      end.to change(test.questions, :count).by(1)
    end

    it 'creates a multiple_choice question with nested options' do
      expect do
        post test_questions_path(test), params: {
          question: {
            body: 'Pick the vowel', answer_type: 'multiple_choice', points: 1.5,
            options_attributes: {
              '0' => { body: 'A', correct: 'true' },
              '1' => { body: 'B', correct: 'false' }
            }
          }
        }
      end.to change(test.questions, :count).by(1)

      expect(test.questions.last.options.count).to eq(2)
    end

    it "denies creating a question on another teacher's test" do
      other_test = create(:test)
      post test_questions_path(other_test), params: {
        question: { body: 'x', answer_type: 'short_text', points: 1, correct_answer: 'y' }
      }
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
