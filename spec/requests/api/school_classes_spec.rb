# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::SchoolClasses', type: :request do
  let(:token) { 'test-token' }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before { allow(ENV).to receive(:fetch).with('ANALYTICS_API_KEY', nil).and_return(token) }

  describe 'GET /api/school_classes' do
    it 'is unauthorized without a token' do
      get api_school_classes_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'succeeds with the correct token' do
      get api_school_classes_path, headers: headers

      expect(response).to have_http_status(:success)
    end

    it 'returns every school class with id and name' do
      class_a = create(:school_class, name: '7-A')
      class_b = create(:school_class, name: '8-B')

      get api_school_classes_path, headers: headers

      expect(response.parsed_body).to contain_exactly(
        { 'id' => class_a.id, 'name' => '7-A' },
        { 'id' => class_b.id, 'name' => '8-B' }
      )
    end
  end
end
