# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'TestAssignments', type: :request do
  let(:teacher) { create(:teacher) }
  let(:test) { create(:test, teacher: teacher) }
  let(:school_class) { create(:school_class) }

  before { sign_in teacher }

  describe 'POST /tests/:test_id/test_assignments' do
    it 'assigns the test to a school class' do
      expect do
        post test_test_assignments_path(test), params: { test_assignment: { school_class_id: school_class.id } }
      end.to change(TestAssignment, :count).by(1)
      expect(response).to redirect_to(test_path(test))
    end
  end

  describe 'GET /test_assignments/:id' do
    it 'renders the class roster, without requiring sign-in' do
      create(:student, school_class: school_class, first_name: 'Ivan', last_name: 'Petrenko')
      assignment = create(:test_assignment, test: test, school_class: school_class)
      sign_out teacher

      get test_assignment_path(assignment)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Ivan Petrenko')
    end

    it "renders in the Test's own locale, not the teacher's session locale" do
      ru_test = create(:test, teacher: teacher, locale: 'ru')
      assignment = create(:test_assignment, test: ru_test, school_class: school_class)
      patch locale_path(locale: 'en')

      get test_assignment_path(assignment)

      expect(response.body).to include('Найди своё имя')
    end
  end

  describe 'DELETE /test_assignments/:id' do
    it 'unassigns the class' do
      assignment = create(:test_assignment, test: test, school_class: school_class)
      expect do
        delete test_assignment_path(assignment)
      end.to change(TestAssignment, :count).by(-1)
    end
  end
end
