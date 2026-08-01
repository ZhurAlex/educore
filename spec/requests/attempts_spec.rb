require 'rails_helper'

RSpec.describe "Attempts", type: :request do
  let(:teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:test) { create(:test, teacher: teacher) }
  let(:student) { create(:student) }

  before { sign_in teacher }

  describe "GET /tests/:test_id/attempts" do
    it "lists attempts for the teacher's own test" do
      attempt = create(:test_attempt, :completed, test: test, student: student)

      get test_attempts_path(test)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(student.full_name)
      expect(response.body).to include(student.school_class.name)
      expect(response.body).to include(attempt.score.to_s)
    end

    it "denies access to another teacher's test" do
      other_test = create(:test, teacher: other_teacher)

      get test_attempts_path(other_test)

      expect(response).to redirect_to(root_path)
    end

    it "groups attempts by school class" do
      class_a = create(:school_class)
      class_b = create(:school_class)
      student_a = create(:student, school_class: class_a)
      student_b = create(:student, school_class: class_b)
      create(:test_attempt, :completed, test: test, student: student_a)
      create(:test_attempt, :completed, test: test, student: student_b)

      get test_attempts_path(test)

      expect(response.body).to include(class_a.name)
      expect(response.body).to include(class_b.name)
    end

  end

  describe "GET /attempts/:id" do
    it "shows per-question detail" do
      mc_question = create(:question, :multiple_choice, test: test)
      response_record = create(:response, :multiple_choice,
        test_attempt: create(:test_attempt, test: test, student: student),
        question: mc_question)

      get attempt_path(response_record.test_attempt)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(mc_question.body)
    end

    it "denies access to another teacher's attempt" do
      other_test = create(:test, teacher: other_teacher)
      attempt = create(:test_attempt, test: other_test, student: student)

      get attempt_path(attempt)

      expect(response).to redirect_to(root_path)
    end
  end
end
