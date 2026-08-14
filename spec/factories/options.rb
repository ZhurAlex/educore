# frozen_string_literal: true

FactoryBot.define do
  factory :option do
    question
    body { Faker::Lorem.word }
    correct { false }
  end
end
