FactoryBot.define do
  factory :response do
    test_attempt
    question
    answer_text { "answer" }
    grading_status { :auto_graded }
    points_awarded { 1.5 }

    trait :multiple_choice do
      # Forced create (not association helper): the after(:create) callback
      # on the :multiple_choice question trait must run to generate options,
      # regardless of the parent's own build/create strategy.
      question { create(:question, :multiple_choice) }
      answer_text { nil }
      option { question.options.find(&:correct?) }
    end
  end
end
