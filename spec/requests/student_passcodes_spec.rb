require 'rails_helper'

RSpec.describe "StudentPasscodes", type: :request do
  let(:school_class) { create(:school_class) }
  let(:student) { create(:student, school_class: school_class, birth_date: Date.new(2013, 3, 7)) }
  let(:test) { create(:test) }
  let(:assignment) { create(:test_assignment, test: test, school_class: school_class) }

  describe "GET /test_assignments/:test_assignment_id/students/:student_id/passcode" do
    it "renders without requiring sign-in" do
      get student_passcode_path(assignment, student)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST .../passcode" do
    it "starts a new attempt and sets the session on a correct passcode" do
      expect {
        post student_passcode_path(assignment, student), params: { passcode: "0703" }
      }.to change(TestAttempt, :count).by(1)

      attempt = TestAttempt.last
      expect(attempt.student).to eq(student)
      expect(attempt.test).to eq(test)
      expect(attempt).to be_in_progress
      expect(response).to redirect_to(test_attempt_path(attempt))
    end

    it "resumes an existing attempt instead of creating a second one (Decision #2)" do
      existing = create(:test_attempt, student: student, test: test)

      expect {
        post student_passcode_path(assignment, student), params: { passcode: "0703" }
      }.not_to change(TestAttempt, :count)

      expect(response).to redirect_to(test_attempt_path(existing))
    end

    it "re-renders with an error on a wrong passcode, without starting an attempt" do
      expect {
        post student_passcode_path(assignment, student), params: { passcode: "9999" }
      }.not_to change(TestAttempt, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
