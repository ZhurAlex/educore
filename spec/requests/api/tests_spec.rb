# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::Tests', type: :request do
  let(:token) { 'test-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(ENV).to receive(:fetch).with('ANALYTICS_API_KEY', nil).and_return(token) }

  describe 'GET /api/tests' do
    it 'is unauthorized without a token' do
      get api_tests_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'succeeds with the correct token' do
      get api_tests_path, headers: headers

      expect(response).to have_http_status(:success)
    end

    context 'filtering' do
      let(:school_class_a) { create(:school_class) }
      let(:school_class_b) { create(:school_class) }
      let(:test_a) { create(:test, title: 'Present Simple') }
      let(:test_b) { create(:test, title: 'Past Simple') }

      before do
        create(:test_assignment, test: test_a, school_class: school_class_a)
        create(:test_assignment, test: test_b, school_class: school_class_b)
      end

      def returned_ids
        response.parsed_body.pluck('id')
      end

      it 'returns every test when no school_class_id is given' do
        get api_tests_path, headers: headers

        expect(returned_ids).to contain_exactly(test_a.id, test_b.id)
      end

      it 'filters by school_class_id' do
        get api_tests_path, params: { school_class_id: school_class_a.id }, headers: headers

        expect(returned_ids).to contain_exactly(test_a.id)
      end

      it 'returns an empty array for a school_class_id with no assigned tests' do
        other_class = create(:school_class)

        get api_tests_path, params: { school_class_id: other_class.id }, headers: headers

        expect(returned_ids).to be_empty
      end
    end

    it 'returns id and title only' do
      test = create(:test, title: 'Present Simple')

      get api_tests_path, headers: headers

      expect(response.parsed_body).to contain_exactly({ 'id' => test.id, 'title' => 'Present Simple' })
    end
  end
end
