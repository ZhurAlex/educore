FactoryBot.define do
  factory :test_attempt do
    student
    test
    status { :in_progress }
    started_at { Time.current }

    trait :completed do
      status { :completed }
      completed_at { Time.current }
      score { 1.5 }
      grade { 2 }
    end
  end
end
