# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuestionGrader do
  subject(:grader) { described_class.new(question) }

  describe '#grade' do
    context 'for a long_text question' do
      let(:question) { create(:question, answer_type: :long_text, points: 3, correct_answer: 'Paris') }

      context 'when the answer is blank' do
        it 'returns a zero-point result without calling Gemini' do
          expect(GeminiApiService).not_to receive(:new)

          result = grader.grade(answer_text: '')

          expect(result.points).to eq(0)
          expect(result.feedback).to be_nil
          expect(result.error).to be_nil
        end
      end

      context 'when Gemini grades the answer successfully' do
        it 'passes the question, answer, and reference answer to Gemini' do
          fake_service = instance_double(GeminiApiService)
          allow(GeminiApiService).to receive(:new).and_return(fake_service)
          expect(fake_service).to receive(:check_answer)
            .with(question.body, 'some answer', 'Paris')
            .and_return({ 'score' => 60, 'feedback' => 'Nice job' })

          grader.grade(answer_text: 'some answer')
        end

        it 'converts the 0-100 score to the question point scale, rounded to 0.5' do
          fake_service = instance_double(GeminiApiService, check_answer: { 'score' => 60, 'feedback' => 'Nice job' })
          allow(GeminiApiService).to receive(:new).and_return(fake_service)

          result = grader.grade(answer_text: 'some answer')

          expect(result.points).to eq(2.0)
          expect(result.feedback).to eq('Nice job')
          expect(result.error).to be_nil
        end
      end

      context 'when Gemini grading fails' do
        it 'returns a zero-point result carrying the error message' do
          fake_service = instance_double(GeminiApiService)
          allow(GeminiApiService).to receive(:new).and_return(fake_service)
          allow(fake_service).to receive(:check_answer)
            .and_raise(GeminiApiService::GradingError, 'Gemini request failed: timeout')

          result = grader.grade(answer_text: 'some answer')

          expect(result.points).to eq(0)
          expect(result.feedback).to be_nil
          expect(result.error).to eq('Gemini request failed: timeout')
        end
      end
    end
  end
end
