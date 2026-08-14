# frozen_string_literal: true

FactoryBot.define do
  factory :school_class do
    sequence(:name) { |n| "7-#{n}" }
  end
end
