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
    it 'lists the class roster by name and last-initial only, linking to the login step' do
      school_class = create(:school_class)
      student = create(:student, school_class: school_class, first_name: 'Tony', last_name: 'Stark')

      get student_entry_path(school_class)

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Tony S.')
      expect(response.body).not_to include(student.full_name)
      expect(response.body).to include(student_history_login_path(school_class, student))
    end
  end
end
