# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'StudentEntry', type: :request do
  describe 'GET /' do
    it 'lists school classes without requiring teacher auth' do
      school_class = create(:school_class, name: '7-A')

      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include(school_class.name)
    end
  end

  describe 'GET /start/:school_class_id' do
    it "lists the class's assigned tests, linking to the results roster (not the QR start roster)" do
      school_class = create(:school_class)
      test = create(:test, title: 'Math Quiz')
      assignment = create(:test_assignment, test: test, school_class: school_class)

      get student_entry_path(school_class)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(test.title)
      expect(response.body).to include(student_entry_results_path(school_class, assignment))
    end
  end

  describe 'GET /start/:school_class_id/tests/:test_assignment_id' do
    it 'lists only students who completed this test, not the whole class roster' do
      school_class = create(:school_class)
      test = create(:test)
      assignment = create(:test_assignment, test: test, school_class: school_class)
      finished = create(:student, school_class: school_class, first_name: 'Finished', last_name: 'Student')
      create(:test_attempt, :completed, student: finished, test: test)
      untouched = create(:student, school_class: school_class, first_name: 'Untouched', last_name: 'Student')

      get student_entry_results_path(school_class, assignment)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(finished.full_name)
      expect(response.body).not_to include(untouched.full_name)
    end

    it 'shows an empty state when nobody has completed the test yet' do
      school_class = create(:school_class)
      assignment = create(:test_assignment, school_class: school_class)

      get student_entry_results_path(school_class, assignment)

      expect(response).to have_http_status(:success)
    end
  end
end
