# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_api_token!

    def authenticate_api_token!
      token = request.headers['Authorization']&.remove('Bearer ')
      expected = ENV.fetch('ANALYTICS_API_KEY', nil)

      # A blank or unset expected token must never match — otherwise a
      # misconfigured (empty-but-set or missing) ANALYTICS_API_KEY would let
      # an unauthenticated request (nil token, "".to_s) through, since
      # secure_compare("", "") is true.
      valid = expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)
      head :unauthorized unless valid
    end
  end
end
