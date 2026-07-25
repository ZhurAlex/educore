# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_24_213224) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "options", force: :cascade do |t|
    t.bigint "question_id", null: false
    t.string "body", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_options_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.bigint "test_id", null: false
    t.text "body", null: false
    t.integer "answer_type", null: false
    t.decimal "points", precision: 5, scale: 2, null: false
    t.string "correct_answer"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["test_id"], name: "index_questions_on_test_id"
  end

  create_table "responses", force: :cascade do |t|
    t.bigint "test_attempt_id", null: false
    t.bigint "question_id", null: false
    t.bigint "option_id"
    t.text "answer_text"
    t.integer "grading_status", default: 0, null: false
    t.decimal "points_awarded", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["option_id"], name: "index_responses_on_option_id"
    t.index ["question_id"], name: "index_responses_on_question_id"
    t.index ["test_attempt_id", "question_id"], name: "index_responses_on_test_attempt_id_and_question_id", unique: true
    t.index ["test_attempt_id"], name: "index_responses_on_test_attempt_id"
  end

  create_table "school_classes", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "students", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.date "birth_date", null: false
    t.bigint "school_class_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id"], name: "index_students_on_school_class_id"
  end

  create_table "teachers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_teachers_on_email", unique: true
    t.index ["reset_password_token"], name: "index_teachers_on_reset_password_token", unique: true
  end

  create_table "test_assignments", force: :cascade do |t|
    t.bigint "test_id", null: false
    t.bigint "school_class_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["school_class_id"], name: "index_test_assignments_on_school_class_id"
    t.index ["test_id", "school_class_id"], name: "index_test_assignments_on_test_id_and_school_class_id", unique: true
    t.index ["test_id"], name: "index_test_assignments_on_test_id"
  end

  create_table "test_attempts", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "test_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "score", precision: 5, scale: 2
    t.integer "grade"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id", "test_id"], name: "index_test_attempts_on_active_student_test", unique: true, where: "(status = 0)"
    t.index ["student_id"], name: "index_test_attempts_on_student_id"
    t.index ["test_id"], name: "index_test_attempts_on_test_id"
  end

  create_table "tests", force: :cascade do |t|
    t.string "title", null: false
    t.bigint "teacher_id", null: false
    t.string "locale", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["teacher_id"], name: "index_tests_on_teacher_id"
  end

  add_foreign_key "options", "questions"
  add_foreign_key "questions", "tests"
  add_foreign_key "responses", "options"
  add_foreign_key "responses", "questions"
  add_foreign_key "responses", "test_attempts"
  add_foreign_key "students", "school_classes"
  add_foreign_key "test_assignments", "school_classes"
  add_foreign_key "test_assignments", "tests"
  add_foreign_key "test_attempts", "students"
  add_foreign_key "test_attempts", "tests"
  add_foreign_key "tests", "teachers"
end
