require 'rails_helper'

RSpec.describe "Students", type: :request do
  let(:teacher) { create(:teacher) }
  let(:school_class) { create(:school_class) }

  before { sign_in teacher }

  describe "POST /school_classes/:school_class_id/students" do
    it "adds a student to the class" do
      expect {
        post school_class_students_path(school_class), params: {
          student: { first_name: "Ivan", last_name: "Petrenko", birth_date: "2012-05-03" }
        }
      }.to change(school_class.students, :count).by(1)
      expect(response).to redirect_to(school_class_path(school_class))
    end
  end

  describe "DELETE /students/:id" do
    it "removes the student" do
      student = create(:student, school_class: school_class)
      expect {
        delete student_path(student)
      }.to change(Student, :count).by(-1)
    end
  end
end
