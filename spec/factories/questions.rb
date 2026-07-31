FactoryBot.define do
  factory :question do
    test
    body { Faker::Lorem.sentence }
    answer_type { :short_text }
    points { 1.5 }
    correct_answer { "answer" }

    trait :multiple_choice do
      answer_type { :multiple_choice }
      correct_answer { nil }

      after(:build) do |question|
        question.options.build(body: "Correct answer", correct: true)
        question.options.build(body: "Incorrect answer", correct: false)
      end
    end
  end
end
