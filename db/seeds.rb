# See docs/SPEC.md "Seed Data" section and Decision #11 — registration is
# closed, so this is the only way to create the Teacher account.

teacher = Teacher.find_or_create_by!(email: ENV.fetch("SEED_TEACHER_EMAIL", "teacher@example.com")) do |t|
  t.name = ENV.fetch("SEED_TEACHER_NAME", "Alexander Zhuravskyi")
  t.password = ENV.fetch("SEED_TEACHER_PASSWORD", "password123")
end

puts "Teacher: #{teacher.email}"

# Demo class/test data — dev convenience only, not needed in production.
if Rails.env.development?
  school_class = SchoolClass.find_or_create_by!(name: "7-A")

  if school_class.students.empty?
    10.times do
      school_class.students.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        birth_date: Faker::Date.birthday(min_age: 10, max_age: 17)
      )
    end
  end

  test = teacher.tests.find_or_create_by!(title: "English Vocabulary Quiz") do |t|
    t.locale = "uk"
  end

  if test.questions.empty?
    multiple_choice = test.questions.create!(
      body: "Which word means 'house'?",
      answer_type: :multiple_choice,
      points: 1
    )
    multiple_choice.options.create!(body: "Home", correct: true)
    multiple_choice.options.create!(body: "Car", correct: false)
    multiple_choice.options.create!(body: "Tree", correct: false)

    test.questions.create!(
      body: "Translate: \"Дякую\"",
      answer_type: :short_text,
      points: 1.5,
      correct_answer: "thank you"
    )
  end

  TestAssignment.find_or_create_by!(test: test, school_class: school_class)

  puts "Seeded: #{school_class.name} (#{school_class.students.count} students), test \"#{test.title}\""
end
