# frozen_string_literal: true

module Api
  class TestAttemptSerializer
    attr_reader :test_attempt

    def initialize(test_attempt)
      @test_attempt = test_attempt
    end

    def as_json(*)
      {
        id: test_attempt.id,
        status: test_attempt.status,
        # .to_f — decimal columns otherwise serialize as strings ("2.0"),
        # not JSON numbers; see docs/API_CONTRACT.md.
        score: test_attempt.score&.to_f,
        student: { id: test_attempt.student.id, name: test_attempt.student.full_name },
        test: { id: test_attempt.test.id, title: test_attempt.test.title, subject: test_attempt.test.subject },
        responses: test_attempt.responses.map do |r|
          {
            question: r.question.body,
            answer: r.question.multiple_choice? ? r.option&.body : r.answer_text,
            points_awarded: r.points_awarded&.to_f,
            max_points: r.question.points&.to_f,
            feedback: r.feedback,
            grading_status: r.grading_status
          }
        end
      }
    end
  end
end
