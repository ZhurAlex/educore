require 'rails_helper'

RSpec.describe "Tests", type: :request do
  let(:teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }

  before { sign_in teacher }

  describe "GET /tests" do
    it "only lists the current teacher's own tests (Decision #10)" do
      mine = create(:test, teacher: teacher, title: "My Test")
      create(:test, teacher: other_teacher, title: "Someone Else's Test")

      get tests_path
      expect(response.body).to include(mine.title)
      expect(response.body).not_to include("Someone Else's Test")
    end
  end

  describe "GET /tests/:id" do
    it "denies access to another teacher's test (Pundit)" do
      test = create(:test, teacher: other_teacher)
      get test_path(test)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /tests" do
    it "creates a test owned by the current teacher" do
      expect {
        post tests_path, params: { test: { title: "English quiz", locale: "uk" } }
      }.to change(teacher.tests, :count).by(1)
    end
  end
end
