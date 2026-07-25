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

      after(:create) do |question|
        create(:option, question: question, correct: true)
        create(:option, question: question, correct: false)
      end
    end
  end
end
