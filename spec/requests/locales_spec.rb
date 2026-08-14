# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Locales', type: :request do
  let(:teacher) { create(:teacher) }

  before { sign_in teacher }

  describe 'PATCH /locale' do
    it 'switches the session locale and persists it across requests' do
      patch locale_path(locale: 'ru')
      expect(response).to redirect_to(root_path)

      get root_path
      expect(response.body).to include('Панель управления')
    end

    it 'ignores an unsupported locale, keeping the default (uk)' do
      patch locale_path(locale: 'de')

      get root_path
      expect(response.body).to include('Панель керування')
    end
  end
end
