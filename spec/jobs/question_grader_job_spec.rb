# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuestionGraderJob do
  describe '#perform' do
    let(:test) { create(:test) }
    let(:student) { create(:student) }
    let(:test_attempt) { create(:test_attempt, student: student, test: test, status: :evaluating) }

    context 'when there are no pending responses' do
      it 'still completes the attempt' do
        described_class.new.perform(test_attempt.id)

        expect(test_attempt.reload).to be_completed
      end
    end

    context 'when a pending response grades successfully' do
      let(:question) { create(:question, test: test, answer_type: :long_text, points: 2, correct_answer: 'Paris') }
      let!(:response) do
        create(:response, test_attempt: test_attempt, question: question, answer_text: 'answer',
                          grading_status: :pending, points_awarded: 0)
      end

      it 'saves the points and feedback, and marks it llm_graded' do
        allow_any_instance_of(Question).to receive(:grade)
          .and_return(QuestionGrader::GradeResult.new(points: 1.5, feedback: 'Nice job'))

        described_class.new.perform(test_attempt.id)

        expect(response.reload).to have_attributes(
          points_awarded: 1.5,
          feedback: 'Nice job',
          grading_status: 'llm_graded'
        )
        expect(test_attempt.reload).to be_completed
      end
    end

    context 'when a pending response fails to grade' do
      let(:question) { create(:question, test: test, answer_type: :long_text, points: 2, correct_answer: 'Paris') }
      let!(:response) do
        create(:response, test_attempt: test_attempt, question: question, answer_text: 'answer',
                          grading_status: :pending, points_awarded: 0)
      end

      it 'marks it manual_check_required without crashing the job' do
        allow_any_instance_of(Question).to receive(:grade)
          .and_return(QuestionGrader::GradeResult.new(error: 'Gemini request failed: timeout'))

        described_class.new.perform(test_attempt.id)

        expect(response.reload.grading_status).to eq('manual_check_required')
        expect(test_attempt.reload).to be_completed
      end
    end
  end
end
