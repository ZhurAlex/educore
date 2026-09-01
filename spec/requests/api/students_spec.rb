# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Students', type: :request do
  let(:token) { 'test-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(ENV).to receive(:fetch).with('ANALYTICS_API_KEY', nil).and_return(token) }

  describe 'GET /api/students' do
    it 'is unauthorized without a token' do
      get api_students_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'succeeds with the correct token' do
      get api_students_path, headers: headers

      expect(response).to have_http_status(:success)
    end

    context 'filtering' do
      let(:school_class_a) { create(:school_class) }
      let(:school_class_b) { create(:school_class) }
      let(:student_a) { create(:student, school_class: school_class_a) }
      let(:student_b) { create(:student, school_class: school_class_b) }

      before do
        student_a
        student_b
      end

      def returned_ids
        response.parsed_body.pluck('id')
      end

      it 'returns every student when no school_class_id is given' do
        get api_students_path, headers: headers

        expect(returned_ids).to contain_exactly(student_a.id, student_b.id)
      end

      it 'filters by school_class_id' do
        get api_students_path, params: { school_class_id: school_class_a.id }, headers: headers

        expect(returned_ids).to contain_exactly(student_a.id)
      end

      it 'returns an empty array for a school_class_id with no students' do
        other_class = create(:school_class)

        get api_students_path, params: { school_class_id: other_class.id }, headers: headers

        expect(returned_ids).to be_empty
      end
    end

    it 'returns id and full_name as name' do
      student = create(:student, first_name: 'Tony', last_name: 'Stark')

      get api_students_path, headers: headers

      expect(response.parsed_body).to contain_exactly({ 'id' => student.id, 'name' => 'Tony Stark' })
    end
  end
end
