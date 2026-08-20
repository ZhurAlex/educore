# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tests', type: :request do
  let(:teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }

  before { sign_in teacher }

  describe 'GET /tests' do
    it "only lists the current teacher's own tests (Decision #10)" do
      mine = create(:test, teacher: teacher, title: 'My Test')
      create(:test, teacher: other_teacher, title: "Someone Else's Test")

      get tests_path
      expect(response.body).to include(mine.title)
      expect(response.body).not_to include("Someone Else's Test")
    end
  end

  describe 'GET /tests/:id' do
    it "denies access to another teacher's test (Pundit)" do
      test = create(:test, teacher: other_teacher)
      get test_path(test)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'shows the localized subject label, not the raw enum key' do
      test = create(:test, teacher: teacher, subject: :english)
      get test_path(test)

      expect(response.body).to include('Англійська')
      expect(response.body).not_to include('english')
    end

    it "shows each question's localized answer_type label, not the raw enum key" do
      test = create(:test, teacher: teacher)
      create(:question, test: test, answer_type: :short_text)
      get test_path(test)

      expect(response.body).to include('Коротка відповідь')
      expect(response.body).not_to include('short_text')
    end
  end

  describe 'POST /tests' do
    it 'creates a test owned by the current teacher' do
      expect do
        post tests_path, params: { test: { title: 'English quiz', locale: 'uk', subject: 'english' } }
      end.to change(teacher.tests, :count).by(1)
    end

    it 'fails validation (not a 500) on an unknown subject' do
      expect do
        post tests_path, params: { test: { title: 'English quiz', locale: 'uk', subject: 'geography' } }
      end.not_to change(teacher.tests, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
