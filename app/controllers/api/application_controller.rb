# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_api_token!

    def authenticate_api_token!
      token = request.headers['Authorization']&.remove('Bearer ')
      expected = ENV.fetch('ANALYTICS_API_KEY', nil)

      valid = expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
      head :unauthorized unless valid
    end
  end
end
