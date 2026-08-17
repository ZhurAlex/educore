# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'StudentHistory', type: :request do
  let(:school_class) { create(:school_class) }
  let(:student) { create(:student, school_class: school_class, birth_date: Date.new(2013, 3, 7)) }

  describe 'GET /start/:school_class_id/students/:student_id/login' do
    it 'renders the passcode form without requiring teacher auth' do
      get student_history_login_path(school_class, student)

      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST .../login' do
    it 'sets the session and redirects to the history page on a correct passcode' do
      post student_history_login_path(school_class, student), params: { passcode: '0703' }

      expect(response).to redirect_to(student_history_path(school_class, student))
      follow_redirect!
      expect(response).to have_http_status(:success)
    end

    it 're-renders with an error on a wrong passcode, without setting the session' do
      post student_history_login_path(school_class, student), params: { passcode: '9999' }

      expect(response).to have_http_status(:unprocessable_content)

      get student_history_path(school_class, student)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /start/:school_class_id/students/:student_id/history' do
    it 'is forbidden without a matching session' do
      get student_history_path(school_class, student)

      expect(response).to have_http_status(:forbidden)
    end

    it "lists the student's own attempts across every test, not another student's" do
      own_test = create(:test, title: 'Math Quiz')
      create(:test_attempt, :completed, student: student, test: own_test)

      other_student = create(:student, school_class: school_class)
      other_test = create(:test, title: 'History Quiz')
      create(:test_attempt, :completed, student: other_student, test: other_test)

      post student_history_login_path(school_class, student), params: { passcode: '0703' }

      get student_history_path(school_class, student)

      expect(response).to have_http_status(:success)
      expect(response.body).to include(own_test.title)
      expect(response.body).not_to include(other_test.title)
    end

    it "404s when the student doesn't belong to the given school_class" do
      other_class = create(:school_class)

      get student_history_login_path(other_class, student)

      expect(response).to have_http_status(:not_found)
    end
  end
end
