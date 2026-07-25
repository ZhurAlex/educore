FactoryBot.define do
  factory :teacher do
    name { Faker::Name.name }
    sequence(:email) { |n| "teacher#{n}@example.com" }
    password { "password123" }
  end
end
