# frozen_string_literal: true

# See docs/SPEC.md "Seed Data" section and Decision #11 — registration is
# closed, so this is the only way to create the Teacher account.

teacher = if Rails.env.development?
            Teacher.find_or_create_by!(email: ENV.fetch('SEED_TEACHER_EMAIL', 'teacher@example.com')) do |t|
              t.name = ENV.fetch('SEED_TEACHER_NAME', 'Alexander Zhuravskyi')
              t.password = ENV.fetch('SEED_TEACHER_PASSWORD', 'password123')
            end
          else
            Teacher.find_or_create_by!(email: ENV.fetch('SEED_TEACHER_EMAIL', 'teacher@example.com')) do |t|
              t.name = ENV.fetch('SEED_TEACHER_NAME')
              t.password = ENV.fetch('SEED_TEACHER_PASSWORD')
            end
          end

Rails.logger.debug { 'Teacher has been created' }

# Demo class/test data — dev convenience only, not needed in production.
if Rails.env.development?
  school_class = SchoolClass.find_or_create_by!(name: '7-A')

  if school_class.students.empty?
    10.times do
      school_class.students.create!(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        birth_date: Faker::Date.birthday(min_age: 10, max_age: 17)
      )
    end
  end

  test = teacher.tests.find_or_create_by!(title: 'English Vocabulary Quiz', subject: 1) do |t|
    t.locale = 'uk'
  end

  if test.questions.empty?
    multiple_choice = test.questions.new(
      body: "Which word means 'house'?",
      answer_type: :multiple_choice,
      points: 1
    )
    multiple_choice.options.build(body: 'Home', correct: true)
    multiple_choice.options.build(body: 'Car', correct: false)
    multiple_choice.options.build(body: 'Tree', correct: false)
    multiple_choice.save!

    test.questions.create!(
      body: 'Translate: "Дякую"',
      answer_type: :short_text,
      points: 1.5,
      correct_answer: 'thank you'
    )
  end

  TestAssignment.find_or_create_by!(test: test, school_class: school_class)

  Rails.logger.debug do
    "Seeded: #{school_class.name} (#{school_class.students.count} students), test \"#{test.title}\""
  end
end

# Avengers-themed demo classes/test — seeded in every environment (including
# production) so the live deploy has something real to click through.
avengers = [
  %w[Tony Stark], %w[Steve Rogers], %w[Natasha Romanoff],
  %w[Bruce Banner], %w[Thor Odinson], %w[Clint Barton],
  %w[Wanda Maximoff], %w[Peter Parker], %w[Carol Danvers],
  %w[Scott Lang]
]

avenger_classes = %w[1-A 1-B].map { |name| SchoolClass.find_or_create_by!(name: name) }

avenger_classes.each_with_index do |avenger_class, class_index|
  next unless avenger_class.students.empty?

  avengers[class_index * 5, 5].each do |first_name, last_name|
    avenger_class.students.create!(
      first_name: first_name,
      last_name: last_name,
      birth_date: (rand(6..7).years.ago - rand(365).days).to_date
    )
  end
end

math_test = teacher.tests.find_or_create_by!(title: 'Math: Basic Arithmetic', subject: 0) do |t|
  t.locale = 'en'
end

if math_test.questions.empty?
  [
    ['How much is 2 + 2?', '4', '3', '5'],
    ['How much is 5 - 3?', '2', '1', '3'],
    ['How much is 3 + 4?', '7', '6', '8'],
    ['Which number is bigger: 8 or 5?', '8', '5', 'they are equal'],
    ['How much is 10 - 6?', '4', '3', '5']
  ].each do |body, correct, wrong_a, wrong_b|
    # Options must exist before the question itself is saved — the
    # "exactly one correct option" validation on Question checks at
    # save time, so `create!` on an empty question would fail here.
    question = math_test.questions.new(body: body, answer_type: :multiple_choice, points: 1)
    question.options.build(body: correct, correct: true)
    question.options.build(body: wrong_a, correct: false)
    question.options.build(body: wrong_b, correct: false)
    question.save!
  end

  [
    ['How much is 1 + 1?', '2'],
    ['How much is 6 + 3?', '9'],
    ['How much is 9 - 4?', '5'],
    ['How many fingers are on one hand?', '5'],
    ['How much is 7 + 2?', '9']
  ].each do |body, answer|
    math_test.questions.create!(body: body, answer_type: :short_text, points: 1, correct_answer: answer)
  end
end

avenger_classes.each do |avenger_class|
  TestAssignment.find_or_create_by!(test: math_test, school_class: avenger_class)
end

Rails.logger.debug do
  "Seeded: #{avenger_classes.map { |c| "#{c.name} (#{c.students.count} students)" }.join(', ')}, " \
    "test \"#{math_test.title}\" (#{math_test.questions.count} questions)"
end
