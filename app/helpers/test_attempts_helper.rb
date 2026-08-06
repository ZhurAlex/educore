module TestAttemptsHelper
  def questions_as_json(questions)
    questions.map do |question|
      {
        id: question.id,
        body: question.body,
        answer_type: question.answer_type,
        points: question.points,
        options: question.options.map do |option|
          {
            id: option.id,
            body: option.body
          }
        end
      }
    end.to_json
  end
end
