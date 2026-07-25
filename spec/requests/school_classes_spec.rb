require 'rails_helper'

RSpec.describe "SchoolClasses", type: :request do
  let(:teacher) { create(:teacher) }

  before { sign_in teacher }

  describe "GET /school_classes" do
    it "lists all school classes (shared across teachers)" do
      create(:school_class, name: "7-A")
      get school_classes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("7-A")
    end
  end

  describe "POST /school_classes" do
    it "creates a school class" do
      expect {
        post school_classes_path, params: { school_class: { name: "8-B" } }
      }.to change(SchoolClass, :count).by(1)
      expect(response).to redirect_to(school_class_path(SchoolClass.last))
    end

    it "re-renders the form on invalid input" do
      post school_classes_path, params: { school_class: { name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /school_classes/:id" do
    it "deletes the school class" do
      school_class = create(:school_class)
      expect {
        delete school_class_path(school_class)
      }.to change(SchoolClass, :count).by(-1)
    end
  end

  context "when not signed in" do
    it "redirects to sign in" do
      sign_out teacher
      get school_classes_path
      expect(response).to redirect_to(new_teacher_session_path)
    end
  end
end
