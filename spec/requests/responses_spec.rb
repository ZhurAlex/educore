# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Responses', type: :request do
  let(:teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:test) { create(:test, teacher: teacher) }
  let(:question) { create(:question, test: test, points: 2) }
  let(:attempt) { create(:test_attempt, :completed, test: test) }
  let(:response_record) { create(:response, test_attempt: attempt, question: question, points_awarded: 0) }

  before { sign_in teacher }

  describe 'PATCH /responses/:id' do
    it "overrides points_awarded, marks teacher_overridden, and recomputes the attempt's score/grade" do
      patch response_path(response_record), params: { response: { points_awarded: 2 } }

      response_record.reload
      expect(response_record.points_awarded).to eq(2)
      expect(response_record).to be_teacher_overridden

      attempt.reload
      expect(attempt.score).to eq(2)
      expect(attempt.grade).to eq(2)

      expect(response).to redirect_to(attempt_path(attempt))
    end

    it "denies access to another teacher's response" do
      other_test = create(:test, teacher: other_teacher)
      other_question = create(:question, test: other_test)
      other_attempt = create(:test_attempt, :completed, test: other_test)
      other_response = create(:response, test_attempt: other_attempt, question: other_question)

      patch response_path(other_response), params: { response: { points_awarded: 99 } }

      expect(response).to redirect_to(root_path)
    end
  end
end
