# frozen_string_literal: true

FactoryBot.define do
  factory :test do
    title { Faker::Lorem.sentence(word_count: 3) }
    teacher
    locale { 'uk' }
  end
end
